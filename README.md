# IJ-predication
1.install IJ-predication

```bash
# clone file
git clone https://github.com/HaoWenhy/IJ-predication.git

cd IJ-predication/script
chmod 755 *

#Adding Environment Variables
echo "export PATH=\"/you/path/IJ-predication/script:\$PATH\" " >> ~/.bashrc

source  ~/.bashrc
```

2.Software Dependency Installation

```bash
mamba install bcftools
mamba install r-base=4.3.1
mamba install conda-forge::py-bgzip
```

3.R package dependency installation

```R
#安装 Bioconductor包vcfR
install.packages("BiocManager",repos = "https://mirrors.tuna.tsinghua.edu.cn/CRAN/")
BiocManager::install("vcfR")
install.packages("randomForest", repos = "https://mirrors.tuna.tsinghua.edu.cn/CRAN/")
install.packages("caret", repos = "https://mirrors.tuna.tsinghua.edu.cn/CRAN/")
install.packages("optparse", repos = "https://mirrors.tuna.tsinghua.edu.cn/CRAN/")
```

4.Software Usage

```bash
cd IJ-predication/test

file.preparation.sh test.vcf test.vcf.gz test.sample final.vcf
Indica-Japonica.prediction.R -v final.vcf -o unknown_samples_predictions.csv
```

