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
mat_dir <- file.path(cr_outs, sample, "outs", "filtered_feature_bc_matrix")
stopifnot(dir.exists(mat_dir))

cat("[R] Loading matrix from:", mat_dir, "\n")
obj <- Read10X(mat_dir) |> CreateSeuratObject(project=sample, min.cells=3, min.features=100)

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
avg <- AverageExpression(obj, features = markers)
avg_mat <- avg$RNA
cluster_labels <- apply(avg_mat, 2, function(x) names(markers)[which.max(x)])
obj$cluster_label <- cluster_labels[as.character(Idents(obj))]

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


