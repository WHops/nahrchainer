% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/seqbuilder.R
\name{model_sds}
\alias{model_sds}
\title{Introduce repeats to a simulated sequence}
\usage{
model_sds(seq_base, sds, uid)
}
\arguments{
\item{seq_base}{A DNA sequence, as character}

\item{sds}{A table including columns 'chromStart', 'chromEnd', 'uid', 'strand'}

\item{uid}{Name of the SD pair to be created. Must appear (exactly) twice in sds.}
}
\description{
This function takes a DNA sequence and an SD instruction (.tsv format),
and introduces this SD.
Also calls add_snps function, to introduce snps in the SD pair,
to create the similarity specified in the input tsv.
}
\examples{

Some example function call or so.

}
\author{
Wolfram Höps
}
