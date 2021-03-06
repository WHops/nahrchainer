% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/sd_compare_input_output.R
\name{compare_sd_paf_input_output}
\alias{compare_sd_paf_input_output}
\title{Compare output sd to input sd. How well did minimap2 do in recovering expected SDs?}
\usage{
compare_sd_paf_input_output(
  preslink,
  ptruelink,
  chunklen,
  runname,
  strand,
  outfile
)
}
\arguments{
\item{preslink}{\link{character/link} a link to a 'results' paf (typically minimap2 output
or processed output)}

\item{chunklen}{\link{numeric} chunk length. This is for naming purposes only. Not so greatly implemented.}

\item{runname}{\link{character} name}

\item{strand}{\link{"+"/"-"} will also appear in output file}

\item{outfile}{the results .txt file which will be written to.}

\item{ptruelink[character/link]}{a link to a ground truth tsv file (single or double entries though?)}
}
\value{
nope
}
\description{

}
\author{
Wolfram Höps
}
