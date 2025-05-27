# IJ-predication
1.install IJ-predication

```bash
# clone file
git clone https://github.com/HaoWenhy/IJ-predication.git

cd IJ-predication/script
chmod 755 *

#Adding Environment Variables
echo "export PATH="/you/path/IJ-predication:$PATH" " >> ~/.bashrc
```

2.软件依赖安装

```bash
mamba install bcftools
```

3.R包依赖安装

```R
#安装 Bioconductor 包 vcfR
if (!requireNamespace("BiocManager", quietly = TRUE))
    install.packages("BiocManager")
BiocManager::install("vcfR")
install.packages("randomForest", repos = "https://mirrors.tuna.tsinghua.edu.cn/CRAN/")
install.packages("caret", repos = "https://mirrors.tuna.tsinghua.edu.cn/CRAN/")
install.packages("optparse", repos = "https://mirrors.tuna.tsinghua.edu.cn/CRAN/")
```

4.软件使用

```bash
 file.preparation.sh  input.vcf input.vcf.gz sample.txt  final.vcf
 Indica-Japonica.prediction.R final.vcf
```

