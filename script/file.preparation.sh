#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

usage() {
  echo "用法: $0 <input.vcf> <output.vcf.gz> <sample_list.txt> [sigSite.txt] <final_output.vcf>"
  echo "  <input.vcf>         : Input uncompressed VCF file"
  echo "  <output.vcf.gz>     : Outputting compressed VCF files"
  echo "  <sample_list.txt>   : File containing sample names, one sample per line"
  echo "  [sigSite.txt]       : Optional: File containing significant loci for filtering"
  echo "                       Default: data/rf_sigout.txt one level up from the directory where the script is located"
  echo "  <final_output.vcf>  : Final output VCF file."
  exit 1
}

# 参数数量检查，允许4或5个参数
if [ $# -lt 4 ] || [ $# -gt 5 ]; then
  usage
fi

# Directory where the script is located (Absolute Path)
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

input="$1"
output="$2"
sample="$3"

if [ $# -eq 4 ]; then
  sigSite="$script_dir/../data/rf_sigout.txt"
  final_out="$4"
else
  sigSite="$4"
  final_out="$5"
fi

# Verify that the file exists
for file in "$input" "$sample" "$sigSite"; do
  if [ ! -f "$file" ]; then
    echo "Error: File \"$file\" does not exist!"
    exit 1
  fi
done

tmp_dir=$(mktemp -d -t tmp_vcf_process_XXXXXX)
trap 'rm -rf "$tmp_dir"' EXIT

echo "Step 1: Compress and index the input VCF file..."
bgzip -c -@ 16 "$input" > "$output"
bcftools index -t "$output"

echo "Step 2: Extract the specified sample information..."
bcftools view -S "$sample" "$output" -Ov > "$tmp_dir/temp.sample.vcf"

echo "Step 3: Modify variant characterization information (add chromosome prefix and modify ID column)..."
awk 'BEGIN {OFS="\t"} 
     /^#/ {print; next} 
     { $1 = "Chr"$1; $3 = $1"__"$2; print }' "$tmp_dir/temp.sample.vcf" > "$tmp_dir/temp.sample.modified.vcf"

echo "Step 4: Extract the information containing the specified significant loci..."
grep "^#" "$tmp_dir/temp.sample.modified.vcf" > "$tmp_dir/temp.sample.head"
grep -f "$sigSite" "$tmp_dir/temp.sample.modified.vcf" > "$tmp_dir/temp.sample.signals"

cat "$tmp_dir/temp.sample.head" "$tmp_dir/temp.sample.signals" > "$final_out"

echo "Finish! The final file is: $final_out"
