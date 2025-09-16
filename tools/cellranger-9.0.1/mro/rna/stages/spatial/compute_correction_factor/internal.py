#
# Copyright (c) 2023 10X Genomics, Inc. All rights reserved.
#

"""Implement downsampling for samples with chevron patterns."""
from __future__ import annotations

import json

import h5py
import numpy as np
from scipy.sparse import csc_matrix

from cellranger.barcodes import utils
from cellranger.spatial.spot_barcode_utils import patterened_barcode_filenames

__MRO__ = """
stage COMPUTE_CORRECTION_FACTOR(
    in  V1PatternFixArgs v1_pattern_fix,
    in  json             barcodes_under_tissue,
    out float            correction_factor,
    out json             affected_barcodes,
    out bool             disable_downsampling,
    src py               "stages/spatial/compute_correction_factor",
)
"""


def decode(arr):
    """Bytes -> str."""
    return np.asarray([item.decode("utf-8") for item in arr])


def read_h5_to_mtx(path):
    """Read filtered_feature_bc_matrix.h5."""
    with h5py.File(path) as f:
        barcodes = decode(np.asarray(f["matrix"]["barcodes"]))
        barcodes = np.asarray([i.split("-")[0] for i in barcodes])
        mat = csc_matrix(
            (f["matrix"]["data"], f["matrix"]["indices"], f["matrix"]["indptr"]),
            shape=f["matrix"]["shape"],
        )

    return (mat.T, barcodes)


def remaining_barcodes(affected, all_barcodes):
    """Identify barcodes to downsample if correction_factor < 1."""
    affected = set(affected)
    with open(all_barcodes) as f:
        all_bcs = set(json.load(f))
    return list(all_bcs - affected)


def compute_correction_factor(mtx, barcodes, pattern_type):
    """Compute correction factor between affected and nearby barcodes."""
    affected_fn, nearby_fn = patterened_barcode_filenames(pattern_type)
    affected = decode(utils.load_barcode_whitelist(affected_fn))
    nearby = decode(utils.load_barcode_whitelist(nearby_fn))

    affected_here = [t for t in affected if t in barcodes]
    nearby_here = [t for t in nearby if t in barcodes]

    if len(affected_here) == 0 or len(nearby_here) == 0:
        return 0, affected_here

    affected_rows = [np.where(barcodes == item)[0][0] for item in affected_here]
    nearby_rows = [np.where(barcodes == item)[0][0] for item in nearby_here]
    affected_means = mtx[affected_rows, :].mean(axis=0)
    nearby_means = mtx[nearby_rows, :].mean(axis=0)
    return np.sum(affected_means) / np.sum(nearby_means), [i + "-1" for i in affected_here]


def main(args, outs):
    if args.v1_pattern_fix is None:
        outs.correction_factor = None
        outs.affected_barcodes = None
        outs.disable_downsampling = True
        return

    mtx, barcodes = read_h5_to_mtx(args.v1_pattern_fix.get("v1_filtered_fbm"))
    correction_factor, affected_here = compute_correction_factor(
        mtx, barcodes, args.v1_pattern_fix.get("v1_pattern_type")
    )

    if not correction_factor:
        outs.correction_factor = None
        outs.affected_barcodes = None
        outs.disable_downsampling = True
        return

    outs.disable_downsampling = False

    if correction_factor >= 1:
        outs.correction_factor = 1.0 / correction_factor
        to_downsample = affected_here

    else:
        outs.correction_factor = correction_factor
        to_downsample = remaining_barcodes(affected_here, args.barcodes_under_tissue)

    with open(outs.affected_barcodes, "w") as f:
        json.dump(to_downsample, f)
