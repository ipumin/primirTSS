% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/transform_cor.R
\name{trans_cor}
\alias{trans_cor}
\title{transform one hg coordinates to another}
\usage{
trans_cor(peak, hg_from, hg_to)
}
\arguments{
\item{peak}{A \code{GRange} object. The genome, the coordinates of which need
to be coverted.}

\item{hg_from}{The genome are coverting from. This parameter can be "hg18",
"hg19" or "hg38", etc.}

\item{hg_to}{Which type the genome is converting to. This parameter can be "hg18",
"hg19" or "hg38", etc. NOTICE \code{hg_from} and \code{hg_to} should be
different from each other.}
}
\value{
A GRanges object.
}
\description{
Convert coordinates between different genomes when necessary.
}
\examples{

peak_df <- data.frame(chrom = c("chr7", "chr7", "chr7"),
                      chromStart = c(128043908, 128045075, 128046242),
                      chromEnd = c(128045074, 128046241, 128047408),
                      stringsAsFactors = FALSE)
peak <-  as(peak_df, "GRanges")

trans_cor(peak, "hg19", "hg38")

}
