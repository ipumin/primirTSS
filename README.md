# primirTSS
primirTSS is a first R package to predict **pri-miRNA** Transcription Start Site.

## 1 Introduction
Identifying human miRNA transcriptional start sites (TSSs) plays a significant role in understanding the transcriptional regulation of miRNA. However, due to the quick capping of pri-miRNA and many miRNA genes may lie in the introns or even exons of other genes, it is difficult to detect miRNA TSSs. miRNA TSSs are cell-specific. And miRNA TSSs are cell-specific, which implies the same miRNA in different cell-lines may start transcribing at different TSSs.

High throughput sequencing, like ChIP-seq, has gradually become an essential and versatile approach for us to identify and understand genomes and their transcriptional processes. 
By integrating H3k4me4 and Pol II data, parting of false positive counts after scoring can be filter out. Besides, DNase I hypersensitive sites(DHS) also imply TSSs, where miRNAs will be accessible and functionally related to transcription activities. And additionally, the expression profile of miRNA and genes in certain cell-line will be considered as well for improve fidelity. By employing all these different kinds of data, here we have developed the primirTSS package to assist users to identify miRNA TSSs in human and to provide them with related information about where miRNA genes lie in the genome, with both command-line and graphical interfaces.


## 2 Find the best putative TSS

### Installation

#### 1 primirTSS

Install the latest release of R, then get `primirTSS` by starting R and entering the commands:

```
devtools::install_github("ipumin/primirTSS")
```

#### 2 Install Java SE Development Kit(JDK)
As Java development environment is indispensable for the main function in our package, it is <span style="border-bottom:1px dashed black;">necessary</span> for users to install [Java SE Development Kit 10](http://www.oracle.com/technetwork/java/javase/downloads/jdk10-downloads-4416644.html) before using `primirTSS`. 

## 3 Getting Started

### Step 1: Process of H3K4me3 and Pol II data

* `peak_merge()`: **Merge one kind of peaks** (H3K4me3 **or** Pol II)

**H3K4me3** and **Pol II** data are key points for accurate prediction our method. 
If one of these to peak data is input, before execute the main function `find_TSS`, the function `peak_merge` should be used to merge adjacent peaks whose distance between each other is less than `n` base pairs and return the merged peaks as an output.

```
library(primirTSS)
peak_df <- data.frame(chrom = c("chr1", "chr2", "chr1"),
                       chromStart = c(450, 460, 680),
                       chromEnd = c(470, 480, 710),
                       stringsAsFactors = FALSE)
peak <-  as(peak_df, "GRanges")
peak_merge(peak, n =250)
```

</br>

* `peak_join()`: **Join two kinds of peaks** (H3K4me3 **and** Pol II)
 
If both of H3K4me3 and Pol II data, after separately merging these two kinds of data first, `peak_join` should be employed to integrate H3K4me3 and Pol II peaks and return the result as `bed_merged` parameter for the main function `find_tss`.

```
peak_df1 <- data.frame(chrom = c("chr1", "chr1", "chr1", "chr2"),
                       start = c(100, 460, 600, 70),
                       end = c(200, 500, 630, 100),
                       stringsAsFactors = FALSE)
peak1 <-  as(peak_df1, "GRanges")

peak_df2 <- data.frame(chrom = c("chr1", "chr1", "chr1", "chr2"),
                       start = c(160, 470, 640, 71),
                       end = c(210, 480, 700, 90),
                       stringsAsFactors = FALSE)
peak2 <-  as(peak_df2, "GRanges")

peak_join(peak1, peak2)
```

### Step 2: Predict most possible TSS for miRNA


* `find_tss` is the main function in the package. The program will first score the candidate TSSs of miRNA and pick up the best candidate in the first step of prediction, (where users can set `flanking_num` and `threshold`). 
* After the first step, H3K4me3 and Pol II data, miRNA expression profiles and DHS check, protein-coding genes expression profiles, if provided, will be integrated to decrease the rate of false positive.

</br>
</br>

There will be different circumstances where not all miRNA expression profiles, DHS data, protein-coding gene('gene') expression profiles are available:

</br>

**Circumstance 1:** no miRNA expression data; then suggest DHS check and protein-coding gene check.

* `ignore_DHS_check`: If users do not have their own miRNA expression profile, the function will employ all the miRNAs already annotated in human, but we suggest using DHS data of the cell line from **ENCODE** to check whether this miRNA is expressed in the cell line or not as well as and all human gene expression profiles from **Ensemble** to check the relative position of TSSs and protein-coding genes to improve the accuracy of prediction.


```
peakfile <- system.file("testdata", "HMEC_h3.csv", package = "primirTSS")
DHSfile <- system.file("testdata", "HMEC_DHS.csv", package = "primirTSS")
peak_h3 <- read.csv(peakfile, stringsAsFactors = FALSE)
DHS <- read.csv(DHSfile, stringsAsFactors = FALSE)
peak_h3 <-  as(peak_h3, "GRanges")
peak <- peak_merge(peak_h3)
```
```
no_ownmiRNA <- find_tss(peak, ignore_DHS_check = FALSE,
                        DHS = DHS, allmirdhs_byforce = FALSE,
                        expressed_gene = "all",
                        allmirgene_byforce = FALSE,
                        seek_tf = FALSE)
```

</br>

**Circumstance 2**: miRNA expression data provided; then no need for DHS check but protein-coding gene check.

* `expressed_mir`: If users have their own miRNA expression profiles, we will use the expressed miRNAs and we suggest not using DHS data of the cell line or others to check the expression of miRNAs.But the protein-coding gene check to check the relative position of TSSs and protein-coding genes is necessary, which helps to verify the precision of prediction.

```
bed_merged <- data.frame(
                chrom = c("chr1", "chr1", "chr1", "chr1", "chr2"),
                start = c(9910686, 9942202, 9996940, 10032962, 9830615),
                end = c(9911113, 9944469, 9998065, 10035458, 9917994),
                stringsAsFactors = FALSE)
bed_merged <- as(bed_merged, "GRanges")

expressed_mir <- c("hsa-mir-5697")

ownmiRNA <- find_tss(bed_merged, expressed_mir = expressed_mir,
                     ignore_DHS_check = TRUE,
                     expressed_gene = "all",
                     allmirgene_byforce = TRUE,
                     seek_tf = FALSE)
```

</br>

* `expressed_gene`: Additionally, users can also specify certain genes expressed in the cell-line being analyzed:



### Step 3: Searching for TFs
* `seek_tf = TRUE`: If user want to predict transcriptional regulation relationship between TF and miRNA, like which TFs might regulate miRNA after get TSSs, they can change `seek_tf = FALSE` from `seek_tf = TRUE` directly in the comprehensive function `find_TSS()`. 


### Step4: Analysis of results 


Here is a demo of predicting TSS for hsa-mir-5697, ignore DHS check.



</br>

**PART1**, `$tss_df`:

```
ownmiRNA$tss_df
```

The first part of the result returns details of predicted TSSs, composed of seven columns: *mir\_name, chrom, stem\_loop\_p1, stem\_loop\_p2, strand mir\_context, tss\_type gene* and *predicted_tss*:

 Entry|Implication
 :----:|----
 **mir_name**| Name of miRNA.
 **chrom** | Chromosome.
 **stem\_loop_p1**| The start site of a stem-loop.
 **stem\_loop_p2**| The end site of a stem-loop.
 **strand**|Polynucleotide strands. (`+/-`)
 **mir_context**|2 types of relative position relationship between stem-loop and protein-coding gene. (`intra/inter`)
 **tss_type**|4 types of predicted TSSs. See the section below TSS types for details.(`host_TSS/intra_TSS/overlap_inter_TSS/inter_TSS`)
 **gene**|Ensembl gene ID.
 **predicted_tss**| Predicted transcription start sites(TSSs).
 **pri\_tss_distance**|The distance between a predicted TSS and the start site of the stem-loop.
 
 
TSSs are cataloged into 4 types as below:

 * **host_TSS**: The TSSs of miRNA that are close to the TSS of protein-coding gene
  implying they may share the same TSS,
  on the condition where `mir_context = intra`.
  (See above: `mir_context`)

 * **intra_TSS:** The TSSs of miRNA that are NOT close to the TSS of protein-coding gene,
  on the condition where `mir_context = intra`.

 * **overlap\_inter_TSS:** The TSSs of miRNA are cataloged as `overlap_inter_TSS` when the pri-miRNA gene overlaps with Ensembl gene, on the condition where "`mir_context = inter`".
  
 * **inter\_inter_TSS:** The TSSs of miRNA are cataloged as `inter_inter_TSS`
  when the miRNA gene does NOT overlap with Ensembl gene,
  on the condition where "`mir_context = inter`".

  (See [Xu HUA et al](https://academic.oup.com/bioinformatics/article-lookup/doi/10.1093/bioinformatics/btw171) 2016 for more details)


</br>


**PART2**, `$log`:

The second part of the result returns **4 logs** created during the process of prediction:

* **`find_nearest_peak_log`**:
  If no peaks locate in the upstream of
  a stem-loop to help determine putative TSSs of miRNA,
  we will fail to find the nearest peak
  and this miRNA will be logged in `find_nearest_peak_log`.

 * **`eponine_score_log`**:
  For a certain miRNA, if none of the candidate TSSs scored with
Eponine method meet the threshold we set,
  we will fail to get a eponine score
  and this miRNA will be logged in `eponine_score_log`.

 * **`DHS_check_log`**:
  For a certain miRNA, if no DHS signals locate
  within 1 kb upstream of each putative TSSs,
  these putative TSSs will be filtered out
  and this miRNA will be logged in `DHS_check_log`.

 * **`gene_filter_log`**:
  For a certain miRNA, when integrating expressed_gene data to improve prediction,
  if no putative TSSs are confirmed after considering the relative
  position relationship among TSSs, stem-loops and expressed genes,
  this miRNA will be filtered out and logged in `gene_filter_log`.


</br>
</br>

## 4 Plot the prediction of TSS for miRNA

* `plot_primiRNA()`: Apart from returning the putative TSS of each miRNA, the package `primirTSS` can also visualize the result and return an image composed of six tracks, (1)TSS, (2)genome, (3)pri-miRNA, (4)the closest gene, (5)eponine score and (6)conservation score.
And the parameters in this function is almost the same as those in `find_tss()` except `expressed_mir` only represents one certain miRNA in `plot_primiRNA()`. **NOTICE** that this function is used for visualizing the TSS prediction of **only one** specific miRNA every single time. 

```
plot_primiRNA(expressed_mir, bed_merged,
              flanking_num = 1000, threshold = 0.7,
              ignore_DHS_check = TRUE,
              DHS, allmirdhs_byforce = TRUE,
              expressed_gene = "all",
              allmirgene_byforce = TRUE)
```

</br>

![plot_tss](http://ww1.sinaimg.cn/large/69a1995bly1ftkytnqlw3j20l90ikdga.jpg)
　
　Figure S1. _**Visualized result for miRNA TSSs by `Plot pri-miRNA TSS()`**_

>As Figure S1 shows, the picture contains information of the pri-miRNA’s coordinate, the closest gene to the miRNA, the eponine score of the miRNA’s candidate TSS and the conservation score of the miRNA’s candidate TSS.
>There are six tracks plotted in return:
>
>
> Entry|Implication
> :----:|-----
> **Chromosome** |Position of miRNA on the chromosome.
> **hg19** |Reference genome coordinate in hg19.
> **pri-miRNA**: |Position of pri-miRNA.
> **Ensemble genes** |Position of related proterin-coding gene.
> **Eponine score** |Score of best putative TSS by Eponine method.
> **Conservation score** |Conservation score of TSS. 　　　　　　　　　　　　　　　　　　　　　　　　

</br>
</br>

## 5 Graphical web interface for prediction


* `run_primirTSSapp()`: A graphical web interface is designed to achieve the functions of `find_tss` and `plot_primiRNA` to help users intuitively and conveniently predict putative TSSs of miRNA. Users can refer documents of the two functions, **Find the best putative TSS** and **Plot the prediction of TSSs for miRNA**, mentioned above for details.
</br>


### TAG1: Find the best putative TSS

![shiny_tss](http://ww1.sinaimg.cn/mw690/69a1995bly1ftlbrh1t6gj219o1ammzs.jpg)
　Figure S2. _**Graphical web interface of `Find pri-miRNA TSS()`**_


>As Figure S2 shows, if we want to use the shiny app, we should select the appropriate options or upload the appropriate files. Histone peaks, Pol II peaks and DHS files are comma-separated values (CSV) files, whose first line is chrom,start,end. Every line of miRNA expression profiles has only one miRNA name which start with hsa-mir, such as hsa-mir-5697. Every line of gene expression profiles has only one gene name which derived from Ensembl, such as ENSG00000261657. All of miRNA expression profiles and gene expression profiles do not have column names. If we have prepared, we can push the Start the analysis button to start finding the TSSs. The process of analysis may need to take a few minutes, and a process bar will appear in right corner.
>
>As a result, we will view first six rows of the result. The first five columns are about <span style="border-bottom:1px dashed black;"> miRNA </span> information, next five columns are about <span style="border-bottom:1px dashed black;"> TSS </span> information. The column of gene denotes the gene whose TSS is closest to the miRNA TSS. The column of pri\_tss\_distance denotes the distance between miRNA TSS and stem-loop. If users choose to get TFs simultaneously, they will have an additional column, `tf`, which stores related TFs.

</br>

### TAG2: Plot pri-miRNA TSS

![shiny_plot](http://ww1.sinaimg.cn/mw690/69a1995bly1ftl9o5f2p0j21a113cmze.jpg)
　Figure S3. _**Graphical web interface of `Plot pri-miRNA TSS()`**_


>As Figure S4 shows, if we select the appropriate options and upload the appropriate files, we can have a picture of miRNA TSSs.

</br>

## Session info
Here is the output of sessionInfo() on the system on which this document was compiled:

```
Session info -------------------------------
 setting  value                       
 version  R version 3.5.0 (2018-04-23)
 system   x86_64, darwin15.6.0        
 ui       RStudio (1.1.442)           
 language (EN)                        
 collate  en_US.UTF-8                 
 tz       Asia/Shanghai               
 date     2018-07-24                  
Packages -----------------------------------
 package                     * version    date       source        
 acepack                       1.4.1      2016-10-29 CRAN (R 3.5.0)
 annotate                      1.58.0     2018-05-01 Bioconductor  
 AnnotationDbi                 1.42.1     2018-05-08 Bioconductor  
 AnnotationFilter              1.4.0      2018-05-01 Bioconductor  
 AnnotationHub                 2.12.0     2018-05-01 Bioconductor  
 assertthat                    0.2.0      2017-04-11 CRAN (R 3.5.0)
 backports                     1.1.2      2017-12-13 CRAN (R 3.5.0)
 base                        * 3.5.0      2018-04-24 local         
 base64enc                     0.1-3      2015-07-28 CRAN (R 3.5.0)
 bindr                         0.1.1      2018-03-13 CRAN (R 3.5.0)
 bindrcpp                    * 0.2.2      2018-03-29 CRAN (R 3.5.0)
 Biobase                       2.40.0     2018-05-01 Bioconductor  
 BiocGenerics                  0.26.0     2018-05-01 Bioconductor  
 BiocInstaller                 1.30.0     2018-05-01 Bioconductor  
 BiocParallel                  1.14.2     2018-07-08 Bioconductor  
 biomaRt                       2.36.1     2018-05-24 Bioconductor  
 Biostrings                    2.48.0     2018-05-01 Bioconductor  
 biovizBase                    1.28.1     2018-07-10 Bioconductor  
 bit                           1.1-14     2018-05-29 CRAN (R 3.5.0)
 bit64                         0.9-7      2017-05-08 CRAN (R 3.5.0)
 bitops                        1.0-6      2013-08-17 CRAN (R 3.5.0)
 blob                          1.1.1      2018-03-25 CRAN (R 3.5.0)
 BSgenome                      1.48.0     2018-05-01 Bioconductor  
 BSgenome.Hsapiens.UCSC.hg38   1.4.1      2018-07-18 Bioconductor  
 caTools                       1.17.1     2014-09-10 CRAN (R 3.5.0)
 checkmate                     1.8.5      2017-10-24 CRAN (R 3.5.0)
 cluster                       2.0.7-1    2018-04-13 CRAN (R 3.5.0)
 CNEr                          1.16.1     2018-06-01 Bioconductor  
 colorspace                    1.3-2      2016-12-14 CRAN (R 3.5.0)
 compiler                      3.5.0      2018-04-24 local         
 crayon                        1.3.4      2017-09-16 CRAN (R 3.5.0)
 curl                          3.2        2018-03-28 CRAN (R 3.5.0)
 data.table                    1.11.4     2018-05-27 CRAN (R 3.5.0)
 datasets                    * 3.5.0      2018-04-24 local         
 DBI                           1.0.0      2018-05-02 CRAN (R 3.5.0)
 DelayedArray                  0.6.1      2018-06-15 Bioconductor  
 devtools                      1.13.6     2018-06-27 CRAN (R 3.5.0)
 dichromat                     2.0-0      2013-01-24 CRAN (R 3.5.0)
 digest                        0.6.15     2018-01-28 CRAN (R 3.5.0)
 DirichletMultinomial          1.22.0     2018-05-01 Bioconductor  
 dplyr                         0.7.6      2018-06-29 CRAN (R 3.5.1)
 ensembldb                     2.4.1      2018-05-07 Bioconductor  
 foreign                       0.8-70     2017-11-28 CRAN (R 3.5.0)
 Formula                       1.2-3      2018-05-03 CRAN (R 3.5.0)
 GenomeInfoDb                  1.16.0     2018-05-01 Bioconductor  
 GenomeInfoDbData              1.1.0      2018-05-30 Bioconductor  
 GenomicAlignments             1.16.0     2018-05-01 Bioconductor  
 GenomicFeatures               1.32.0     2018-05-01 Bioconductor  
 GenomicRanges                 1.32.4     2018-07-13 Bioconductor  
 GenomicScores                 1.4.1      2018-05-23 Bioconductor  
 ggplot2                       3.0.0      2018-07-03 CRAN (R 3.5.0)
 glue                          1.3.0      2018-07-17 CRAN (R 3.5.0)
 GO.db                         3.6.0      2018-05-30 Bioconductor  
 graphics                    * 3.5.0      2018-04-24 local         
 grDevices                   * 3.5.0      2018-04-24 local         
 grid                          3.5.0      2018-04-24 local         
 gridExtra                     2.3        2017-09-09 CRAN (R 3.5.0)
 gtable                        0.2.0      2016-02-26 CRAN (R 3.5.0)
 gtools                        3.8.1      2018-06-26 CRAN (R 3.5.0)
 Gviz                          1.24.0     2018-05-01 Bioconductor  
 Hmisc                         4.1-1      2018-01-03 CRAN (R 3.5.0)
 hms                           0.4.2      2018-03-10 CRAN (R 3.5.0)
 htmlTable                     1.12       2018-05-26 CRAN (R 3.5.0)
 htmltools                     0.3.6      2017-04-28 CRAN (R 3.5.0)
 htmlwidgets                   1.2        2018-04-19 CRAN (R 3.5.0)
 httpuv                        1.4.4.2    2018-07-02 CRAN (R 3.5.0)
 httr                          1.3.1      2017-08-20 CRAN (R 3.5.0)
 interactiveDisplayBase        1.18.0     2018-05-01 Bioconductor  
 IRanges                       2.14.10    2018-05-16 Bioconductor  
 JASPAR2018                    1.1.1      2018-05-30 Bioconductor  
 KEGGREST                      1.20.1     2018-06-27 Bioconductor  
 knitr                         1.20       2018-02-20 CRAN (R 3.5.0)
 later                         0.7.3      2018-06-08 CRAN (R 3.5.0)
 lattice                       0.20-35    2017-03-25 CRAN (R 3.5.0)
 latticeExtra                  0.6-28     2016-02-09 CRAN (R 3.5.0)
 lazyeval                      0.2.1      2017-10-29 CRAN (R 3.5.0)
 magrittr                      1.5        2014-11-22 CRAN (R 3.5.0)
 Matrix                        1.2-14     2018-04-13 CRAN (R 3.5.0)
 matrixStats                   0.53.1     2018-02-11 CRAN (R 3.5.0)
 memoise                       1.1.0      2017-04-21 CRAN (R 3.5.0)
 methods                     * 3.5.0      2018-04-24 local         
 mime                          0.5        2016-07-07 CRAN (R 3.5.0)
 munsell                       0.5.0      2018-06-12 CRAN (R 3.5.0)
 nnet                          7.3-12     2016-02-02 CRAN (R 3.5.0)
 parallel                      3.5.0      2018-04-24 local         
 phastCons100way.UCSC.hg38     3.7.1      2018-07-18 Bioconductor  
 pillar                        1.3.0      2018-07-14 CRAN (R 3.5.0)
 pkgconfig                     2.0.1      2017-03-21 CRAN (R 3.5.0)
 plyr                          1.8.4      2016-06-08 CRAN (R 3.5.0)
 png                           0.1-7      2013-12-03 CRAN (R 3.5.0)
 poweRlaw                      0.70.1     2017-08-29 CRAN (R 3.5.0)
 prettyunits                   1.0.2      2015-07-13 CRAN (R 3.5.0)
 primirTSS                   * 0.0.0.9000 2018-07-24 local         
 progress                      1.2.0      2018-06-14 CRAN (R 3.5.0)
 promises                      1.0.1      2018-04-13 CRAN (R 3.5.0)
 ProtGenerics                  1.12.0     2018-05-01 Bioconductor  
 purrr                         0.2.5      2018-05-29 CRAN (R 3.5.0)
 R.methodsS3                   1.7.1      2016-02-16 CRAN (R 3.5.0)
 R.oo                          1.22.0     2018-04-22 CRAN (R 3.5.0)
 R.utils                       2.6.0      2017-11-05 CRAN (R 3.5.0)
 R6                            2.2.2      2017-06-17 CRAN (R 3.5.0)
 RColorBrewer                  1.1-2      2014-12-07 CRAN (R 3.5.0)
 Rcpp                          0.12.17    2018-05-18 CRAN (R 3.5.0)
 RCurl                         1.95-4.11  2018-07-15 CRAN (R 3.5.0)
 readr                         1.1.1      2017-05-16 CRAN (R 3.5.0)
 reshape2                      1.4.3      2017-12-11 CRAN (R 3.5.0)
 rlang                         0.2.1      2018-05-30 CRAN (R 3.5.0)
 rpart                         4.1-13     2018-02-23 CRAN (R 3.5.0)
 Rsamtools                     1.32.2     2018-07-03 Bioconductor  
 RSQLite                       2.1.1      2018-05-06 CRAN (R 3.5.0)
 rstudioapi                    0.7        2017-09-07 CRAN (R 3.5.0)
 rtracklayer                   1.40.3     2018-06-02 Bioconductor  
 S4Vectors                     0.18.3     2018-06-08 Bioconductor  
 scales                        0.5.0      2017-08-24 CRAN (R 3.5.0)
 seqLogo                       1.46.0     2018-05-01 Bioconductor  
 shiny                         1.1.0      2018-05-17 CRAN (R 3.5.0)
 splines                       3.5.0      2018-04-24 local         
 stats                       * 3.5.0      2018-04-24 local         
 stats4                        3.5.0      2018-04-24 local         
 stringi                       1.2.3      2018-06-12 CRAN (R 3.5.0)
 stringr                       1.3.1      2018-05-10 CRAN (R 3.5.0)
 SummarizedExperiment          1.10.1     2018-05-11 Bioconductor  
 survival                      2.42-6     2018-07-13 CRAN (R 3.5.0)
 TFBSTools                     1.18.0     2018-05-01 Bioconductor  
 TFMPvalue                     0.0.8      2018-05-16 CRAN (R 3.5.0)
 tibble                        1.4.2      2018-01-22 CRAN (R 3.5.0)
 tidyr                         0.8.1      2018-05-18 CRAN (R 3.5.0)
 tidyselect                    0.2.4      2018-02-26 CRAN (R 3.5.0)
 tools                         3.5.0      2018-04-24 local         
 utils                       * 3.5.0      2018-04-24 local         
 VariantAnnotation             1.26.1     2018-07-04 Bioconductor  
 VGAM                          1.0-5      2018-02-07 CRAN (R 3.5.0)
 withr                         2.1.2      2018-03-15 CRAN (R 3.5.0)
 XML                           3.98-1.12  2018-07-15 CRAN (R 3.5.0)
 xtable                        1.8-2      2016-02-05 CRAN (R 3.5.0)
 XVector                       0.20.0     2018-05-01 Bioconductor  
 yaml                          2.1.19     2018-05-01 CRAN (R 3.5.0)
 zlibbioc                      1.26.0     2018-05-01 Bioconductor 
```
