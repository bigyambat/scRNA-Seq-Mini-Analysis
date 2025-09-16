#
# Copyright (c) 2023 10X Genomics, Inc. All rights reserved.
#

"""Implement downsampling for samples with chevron patterns."""

import h5py
import numpy as np
from scipy.sparse import csc_matrix

from cellranger.barcodes import utils
from cellranger.spatial.spot_barcode_utils import patterened_barcode_filenames

__MRO__ = """
stage COMPUTE_CORRECTION_FACTOR(
    in  V1PatternFixArgs     v1_pattern_fix,
    src py                   "stages/spatial/check_correction_factor",
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


def compute_correction_factor(mtx, barcodes, pattern_type):
    """Compute correction factor between affected and nearby barcodes."""
    affected_fn, nearby_fn = patterened_barcode_filenames(pattern_type)
    affected = decode(utils.load_barcode_whitelist(affected_fn))
    nearby = decode(utils.load_barcode_whitelist(nearby_fn))

    affected_here = [t for t in affected if t in barcodes]
    nearby_here = [t for t in nearby if t in barcodes]

    if len(affected_here) == 0 or len(nearby_here) == 0:
        return 0

    affected_rows = [np.where(barcodes == item)[0][0] for item in affected_here]
    nearby_rows = [np.where(barcodes == item)[0][0] for item in nearby_here]
    affected_means = mtx[affected_rows, :].mean(axis=0)
    nearby_means = mtx[nearby_rows, :].mean(axis=0)
    return np.sum(affected_means) / np.sum(nearby_means)


# pylint: disable=unused-argument
def main(args, outs):
    if args.v1_pattern_fix is None:
        return
    mtx, barcodes = read_h5_to_mtx(args.filtered_fbm)
    correction_factor = compute_correction_factor(
        mtx, barcodes, args.v1_pattern_fix["v1_pattern_type"]
    )
    assert (
        0.8 < correction_factor < 1.2
    ), "Downsampling failed. This is likely due to using an incorrect v1-filtered-fbm input."
