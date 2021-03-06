#!/usr/bin/env Rscript
args = commandArgs(trailingOnly=TRUE)
system('mkdir -p testing')
save(args, file = 'testing/reumimspm_args.Rdata')
base_dir = args[6]
SRS = args[1]
REF = args[2]

matrix_file_dir <- args[3]
bus_pfx <- args[4]
stats_file <- args[5]

outpfx <- ifelse(bus_pfx == 'spliced', 'matrix.Rdata', 'unspliced_matrix.Rdata')
out_matrix_file <- paste(matrix_file_dir, outpfx, sep = '/')

library(Seurat)
library(BUSpaRse)
library(Matrix)
library(DropletUtils)
library(readr)

# input data from project

raw_matrix <- BUSpaRse::read_count_output(matrix_file_dir,bus_pfx, FALSE)
dim(raw_matrix)
tot_counts <- Matrix::colSums(raw_matrix)


bc_rank <- try({ barcodeRanks(raw_matrix) })
n=50
while(class(bc_rank) == 'try-error' & n >=0) {
  bc_rank <- try({ barcodeRanks(raw_matrix,lower = n) })
  n = n-10
}

if(n <0){ # there were no samples 
  bc_rank  = barcodeRanks(raw_matrix,lower = 0, fit.bounds=c(0,10000 ))

}

# qplot(bc_rank$total, bc_rank$rank, geom = "line") +
#   geom_vline(xintercept = metadata(bc_rank)$knee, color = "blue", linetype = 2) +
#   geom_vline(xintercept = metadata(bc_rank)$inflection, color = "green", linetype = 2) +
#   annotate("text", y = 1000, x = 1.5 * c(metadata(bc_rank)$knee, metadata(bc_rank)$inflection),
#   label = c("knee", "inflection"), color = c("blue", "green")) +
#   scale_x_log10() +
#   scale_y_log10() +
#   labs(y = "Barcode rank", x = "Total UMI count")

res_matrix <- raw_matrix[, tot_counts > metadata(bc_rank)$inflection]
# dim(res_matrix)
# 
# seu <- CreateSeuratObject(res_matrix, min.cells = 3) %>%
#   NormalizeData(verbose = FALSE) %>%
#   ScaleData(verbose = FALSE) %>%
#   FindVariableFeatures(verbose = FALSE)
# 
# 
# seu <- RunPCA(seu, verbose = FALSE, npcs = 30)
# ElbowPlot(seu, ndims = 30)
# DimPlot(seu, reduction = "pca", pt.size = 0.5)
# 
# seu <- RunTSNE(seu, dims = 1:20, check_duplicates = FALSE)
# DimPlot(seu, reduction = "tsne", pt.size = 0.5)

# write out pre/post UMI counts
stats <- data.frame('Gene_Number' = c(dim(raw_matrix)[1], dim(res_matrix)[1]), 
                    'UMI_Count' = c(dim(raw_matrix)[2], dim(res_matrix)[2]),
                    'State' = c('Raw', 'Processed'),
                    'SRS' = c(SRS,SRS))
write_tsv(stats, path = stats_file)

# save pared down counts
save(res_matrix, file = out_matrix_file)
message('finished successfully')
