#!/usr/bin/env Rscript

# Loading the necessary libraries
suppressPackageStartupMessages({
  library(vcfR)
  library(randomForest)
  library(caret)
  library(optparse)  
})

# Parsing command line arguments
option_list <- list(
  make_option(c("-v", "--vcf"), type = "character", default = NULL,
              help = "Unknown sample VCF file path", metavar = "file"),
  make_option(c("-m", "--model"), type = "character", default = NULL,
              help = "Random forest model file path (rds format), default upper level data folder", metavar = "file"),
  make_option(c("-d", "--data"), type = "character", default = NULL,
              help = "Training data CSV file path, default parent data folder", metavar = "file"),
  make_option(c("-o", "--output"), type = "character", default = "unknown_samples_predictions.csv",
              help = "Predictions output CSV file name, default unknown_samples_predictions.csv", metavar = "file")
)

opt_parser <- OptionParser(option_list = option_list)
opt <- parse_args(opt_parser)

#  Parameter checking
if (is.null(opt$vcf)) {
  print_help(opt_parser)
  stop("Must specify unknown sample VCF file path --vcf", call. = FALSE)
}

# Get the directory where the script is located, and automatically locate the default file path.
get_script_path <- function() {
  # Getting the path to a script when Rscript is executed
  cmdArgs <- commandArgs(trailingOnly = FALSE)
  fileArgName <- "--file="
  pathIdx <- grep(fileArgName, cmdArgs)
  if (length(pathIdx) > 0) {
    normalizePath(sub(fileArgName, "", cmdArgs[pathIdx]))
  } else {
    # R interactive environment can not be automatically obtained, return to the current working directory
    getwd()
  }
}

script_path <- get_script_path()
script_dir <- dirname(script_path)
parent_data_dir <- normalizePath(file.path(script_dir, "..", "data"))

# Set default paths for model files and training data (if not parameterized by the user)
model_file <- ifelse(is.null(opt$model),
                     file.path(parent_data_dir, "rf_model_cv.rds"),
                     opt$model)

data_file <- ifelse(is.null(opt$data),
                    file.path(parent_data_dir, "data.csv"),
                    opt$data)

# Loading models and data
if (!file.exists(model_file)) {
  stop(paste("Model file does not exist:", model_file))
}
if (!file.exists(data_file)) {
  stop(paste("Training data file does not exist:", data_file))
}

cat("Load model:", model_file, "\n")
rf_model_cv <- readRDS(model_file)

cat("Load the training data:", data_file, "\n")
data <- read.csv(data_file, header = TRUE, stringsAsFactors = FALSE)

# Read unknown sample VCF
unknown_vcf_file <- opt$vcf
if (!file.exists(unknown_vcf_file)) {
  stop(paste("Unknown sample VCF file does not exist", unknown_vcf_file))
}
cat("Read the unknown sample VCF:", unknown_vcf_file, "\n")
unknown_vcf_data <- read.vcfR(unknown_vcf_file)

# Extract genotype data, convert to values, transpose: rows = samples, columns = features
unknown_genotype_data <- extract.gt(unknown_vcf_data, element = "GT", as.numeric = TRUE)
unknown_genotype_df <- as.data.frame(t(unknown_genotype_data))
unknown_genotype_df[is.na(unknown_genotype_df)] <- 0

# Get the features used for training (remove the Sample and Group columns)
train_features <- colnames(data)[!(colnames(data) %in% c("Sample", "Group"))]

# Calculation of common features
common_features <- intersect(train_features, colnames(unknown_genotype_df))
cat("Number of shared features:", length(common_features), "\n")

# Construct a predictive data frame, retaining only shared features
predict_df <- unknown_genotype_df[, common_features, drop = FALSE]


predict_df[is.na(predict_df)] <- 0

# The order of features used for prediction in the training set
common_features_ordered <- train_features[train_features %in% common_features]

# Reorder predictive data columns
predict_df <- predict_df[, common_features_ordered, drop = FALSE]

missing_in_unknown <- setdiff(train_features, common_features)
if(length(missing_in_unknown) > 0){
  cat("Number of features in the missing training set for unknown samples:", length(missing_in_unknown), "will make up 0\n")
  for(f in missing_in_unknown){
    predict_df[[f]] <- 0
  }
  predict_df <- predict_df[, train_features, drop = FALSE]
}

# projected
unknown_predictions <- predict(rf_model_cv, predict_df)

# Table of constructive results
prediction_results <- data.frame(Sample = rownames(predict_df),
                                 PredictedGroup = unknown_predictions)

print(prediction_results)

# Write the results
output_file <- opt$output
write.csv(prediction_results, file = output_file, row.names = FALSE, quote = FALSE)

cat("Predictions have been saved to：", output_file, "\n")
