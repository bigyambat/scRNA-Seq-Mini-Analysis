suppressPackageStartupMessages({
  library(Seurat)
  library(tidyverse)
  library(patchwork)
})

root_dir <- normalizePath(file.path(dirname(".")))
config_path <- file.path(root_dir, "config", "config.yaml")
results_dir <- file.path(root_dir, "results")
cr_outs <- file.path(results_dir, "cellranger")
seurat_dir <- file.path(results_dir, "seurat")
report_dir <- file.path(root_dir, "report")
dir.create(seurat_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(report_dir, showWarnings = FALSE, recursive = TRUE)

yaml <- tryCatch({
  suppressWarnings(yaml::read_yaml(config_path))
}, error=function(e) NULL)

get_or <- function(x, default) {
  if (is.null(x)) default else x
}

min_features <- get_or(yaml$qc$min_features, 200)
max_mt <- get_or(yaml$qc$max_mt_percent, 15)
n_hvgs <- get_or(yaml$qc$n_hvgs, 2000)

sample <- yaml$datasets$tenx$sample_name
cat("[R] Sample name:", sample, "\n")
cat("[R] CellRanger output directory:", cr_outs, "\n")
cat("[R] CellRanger output contents:\n")
list.files(cr_outs, full.names = TRUE) |> cat(sep = "\n")

sample_dir <- file.path(cr_outs, sample)
cat("[R] Sample directory:", sample_dir, "\n")
cat("[R] Sample directory exists:", dir.exists(sample_dir), "\n")
if (dir.exists(sample_dir)) {
  cat("[R] Sample directory contents:\n")
  list.files(sample_dir, full.names = TRUE) |> cat(sep = "\n")
}

mat_dir <- file.path(cr_outs, sample, "outs", "filtered_feature_bc_matrix")
cat("[R] Matrix directory:", mat_dir, "\n")
cat("[R] Matrix directory exists:", dir.exists(mat_dir), "\n")
stopifnot(dir.exists(mat_dir))

cat("[R] Loading matrix from:", mat_dir, "\n")
cat("[R] Matrix directory contents:\n")
list.files(mat_dir, full.names = TRUE) |> cat(sep = "\n")

# Check if matrix files exist
matrix_file <- file.path(mat_dir, "matrix.mtx.gz")
features_file <- file.path(mat_dir, "features.tsv.gz")
barcodes_file <- file.path(mat_dir, "barcodes.tsv.gz")

cat("[R] Checking matrix files:\n")
cat("  Matrix file exists:", file.exists(matrix_file), "\n")
cat("  Features file exists:", file.exists(features_file), "\n")
cat("  Barcodes file exists:", file.exists(barcodes_file), "\n")

# Try to read the matrix with error handling
tryCatch({
  # First try Read10X, but if it fails, read manually
  cat("[R] Attempting to read matrix with Read10X...\n")
  mat <- Read10X(mat_dir)
  cat("[R] Read10X successful\n")
  cat("[R] Matrix dimensions:", dim(mat), "\n")
  cat("[R] Matrix class:", class(mat), "\n")
  
  if (is.list(mat)) {
    cat("[R] Matrix is a list with names:", names(mat), "\n")
    mat <- mat[[1]]  # Use the first (and usually only) element
  }
  
}, error = function(e) {
  cat("[R] Read10X failed:", e$message, "\n")
  cat("[R] Reading matrix files manually...\n")
  
  # Read matrix files manually
  library(Matrix)
  
  # Read features (genes)
  features <- read.table(features_file, sep = "\t", header = FALSE, stringsAsFactors = FALSE)
  cat("[R] Features file dimensions:", dim(features), "\n")
  cat("[R] First few features:", head(features[,1], 3), "\n")
  
  # Read barcodes (cells)
  barcodes <- read.table(barcodes_file, sep = "\t", header = FALSE, stringsAsFactors = FALSE)
  cat("[R] Barcodes file dimensions:", dim(barcodes), "\n")
  cat("[R] First few barcodes:", head(barcodes[,1], 3), "\n")
  
  # Read matrix
  mat <- readMM(matrix_file)
  cat("[R] Matrix dimensions after readMM:", dim(mat), "\n")
  
  # Set rownames and colnames
  rownames(mat) <- features[,1]
  colnames(mat) <- barcodes[,1]
  cat("[R] Rownames and colnames set\n")
  cat("[R] Final matrix dimensions:", dim(mat), "\n")
  cat("[R] Final matrix class:", class(mat), "\n")
})

# Check if matrix has rownames
cat("[R] Matrix rownames length:", length(rownames(mat)), "\n")
cat("[R] First few rownames:", head(rownames(mat), 3), "\n")

# Ensure matrix has proper rownames before creating Seurat object
if (is.null(rownames(mat)) || length(rownames(mat)) == 0) {
  stop("Matrix has no rownames")
}

obj <- CreateSeuratObject(mat, project=sample, min.cells=3, min.features=100)
cat("[R] Seurat object created successfully\n")

obj[["percent.mt"]] <- PercentageFeatureSet(obj, pattern = "^MT-")

p1 <- VlnPlot(obj, features=c("nFeature_RNA","nCount_RNA","percent.mt"), ncol=3)
ggsave(file.path(seurat_dir, "qc_violin.png"), p1, width=10, height=4, dpi=200)

obj <- subset(obj, subset = nFeature_RNA > min_features & percent.mt < max_mt)
obj <- NormalizeData(obj)
obj <- FindVariableFeatures(obj, nfeatures = n_hvgs)
obj <- ScaleData(obj)
obj <- RunPCA(obj)
obj <- FindNeighbors(obj, dims=1:20)
obj <- FindClusters(obj, resolution=0.5)
obj <- RunUMAP(obj, dims=1:20)

umap <- DimPlot(obj, reduction = "umap", group.by = "seurat_clusters", label=TRUE) + NoLegend()
ggsave(file.path(seurat_dir, "umap_clusters.png"), umap, width=6, height=5, dpi=200)

markers <- c(T.cells = "CD3D", B.cells = "MS4A1", NK = "NKG7", Monocytes = "LYZ", DC = "FCER1A")
feat <- FeaturePlot(obj, features = unname(markers), cols = c("lightgrey","red"), ncol = 3)
ggsave(file.path(seurat_dir, "marker_features.png"), feat, width=9, height=6, dpi=200)

# naive annotation by max avg marker expression per cluster
cat("[R] Computing cluster annotations...\n")
tryCatch({
  avg <- AverageExpression(obj, features = markers)
  avg_mat <- avg$RNA
  cluster_labels <- apply(avg_mat, 2, function(x) names(markers)[which.max(x)])
  obj$cluster_label <- cluster_labels[as.character(Idents(obj))]
  cat("[R] Cluster annotations completed successfully\n")
}, error = function(e) {
  cat("[R] Error in cluster annotation:", e$message, "\n")
  cat("[R] Using cluster numbers as labels\n")
  obj$cluster_label <<- paste0("Cluster_", Idents(obj))
})

# Ensure cluster_label column exists
if (!"cluster_label" %in% colnames(obj@meta.data)) {
  cat("[R] Creating cluster_label column as fallback\n")
  obj$cluster_label <- paste0("Cluster_", Idents(obj))
}
cat("[R] Cluster labels:", unique(obj$cluster_label), "\n")

lab_umap <- DimPlot(obj, reduction="umap", group.by="cluster_label", label=TRUE)
ggsave(file.path(seurat_dir, "umap_labels.png"), lab_umap, width=6, height=5, dpi=200)

# simple trajectory: order clusters along first PC as pseudotime proxy
emb <- Embeddings(obj, "pca")
pt <- scale(emb[,1])[,1]
obj$pseudotime_simple <- as.numeric(rank(pt))/length(pt)
pt_plot <- FeaturePlot(obj, features="pseudotime_simple")
ggsave(file.path(seurat_dir, "pseudotime.png"), pt_plot, width=6, height=5, dpi=200)

saveRDS(obj, file.path(seurat_dir, paste0(sample, "_seurat.rds")))

cat("[R] Seurat analysis complete\n")
