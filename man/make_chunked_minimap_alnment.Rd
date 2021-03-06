% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/seqbuilder_functions.R
\name{make_chunked_minimap_alnment}
\alias{make_chunked_minimap_alnment}
\title{A core wrapper function. Give me two fasta files and I'll give you
an output paf and a dotplot pdf.}
\usage{
make_chunked_minimap_alnment(
  targetfasta,
  queryfasta,
  outpaf,
  chunklen = 1000,
  keep_ref = 10000,
  minsdlen = 2000,
  plot_size = 10,
  saveplot = T,
  savepaf = T,
  quadrantsize = 1e+05,
  hllink = F,
  hltype = F,
  targetrange = NULL,
  queryrange = NULL,
  wholegenome = F
)
}
\arguments{
\item{targetfasta}{\link{character/link} link to the 'target' single-sequence fasta (sometimes reference, e.g. chm13.)}

\item{queryfasta}{\link{character/link} link to the 'query' single-sequence fasta.}

\item{outpaf}{\link{character/link} Path to the output paffile to be written.}

\item{chunklen}{\link{numeric} length of sequence chunks to split the query to (default = 1000 bp.)}

\item{keep_ref}{\link{numeric} Number of alignments to keep or something. Plotting parameter.}

\item{plot_size}{\link{numeric} Plot size in inch.}

\item{hllink}{\link{character/link} link to an SD annotation file (bed, tsv or paf) to include as
highlights in the plot.}

\item{hltype}{\link{character} filetype of hllink. Can be 'NULL', 'bed', 'tsv', 'paf'.}

\item{outplot}{\link{character/link} Path to the output plot to be written.}

\item{outsd}{\link{character/link} Outputfile for the modified SD tsv file.}
}
\value{
nothing. But output files written.
}
\description{
This is sitting at the core of the nahrchainer module. It ties
together core modules, such as query-sequence chunking, minimap2 alignment,
paf recombination and plotting. s
}
\author{
Wolfram Höps
}
