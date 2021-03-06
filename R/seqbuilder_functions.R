

#' A wrapper for extracting values from the config.
#' @author Wolfram Höps
#' @export
query_config <- function(param) {
  configfile = "~/PhD/projects/nahrcall/nahrchainer/conf/config.yml"
  return(config::get(param, file = configfile))
}

#' Simple helperfunction to extract part of a fasta into a character.
#'
#' @description Simple helperfunction to extract part of a fasta into a character.
#' Can be useful e.g. to visualize part of a fasta with an exact dotplot.
#'
#' @param inputfasta [character/link] link to a single-sequence fasta
#' @param range [numeric 2x1 vctor] Sequence range to extract. E.g. range=c(10,100) extracts bases 10 to 100.
#' @return A DNA sequence as a character
#'
#' @author Wolfram Höps
#' @export
get_subseq <- function(input_fasta, range = NULL) {
  # Load
  seq1f = Biostrings::readDNAStringSet(input_fasta)
  seq1seq = as.character(seq1f)
  if (!is.null(range)) {
    seq1seq = substr(seq1seq, range[1], range[2])
  }
  return(seq1seq)
}


#' A testfunction to see if nahrtoolkit is loaded
#' @author Wolfram Höps
#' @export
confirm_loaded_nahr <- function() {
  print('The NAHRtoolkit is loaded and ready to go.')
}

#' Print version number.
#' @author Wolfram Höps
#' @export
version_nahr <- function() {
  print('This is version 0.95 from Feb 14th, 2022.')
}

#' A core wrapper function. Give me two fasta files and I'll give you
#' an output paf and a dotplot pdf.
#'
#' @description This is sitting at the core of the nahrchainer module. It ties
#' together core modules, such as query-sequence chunking, minimap2 alignment,
#' paf recombination and plotting. s
#'
#' @param targetfasta [character/link] link to the 'target' single-sequence fasta (sometimes reference, e.g. chm13.)
#' @param queryfasta [character/link] link to the 'query' single-sequence fasta.
#' @param chunklen [numeric] length of sequence chunks to split the query to (default = 1000 bp.)
#' @param hllink [character/link] link to an SD annotation file (bed, tsv or paf) to include as
#' highlights in the plot.
#' @param hltype [character] filetype of hllink. Can be 'NULL', 'bed', 'tsv', 'paf'.
#' @param outpaf [character/link] Path to the output paffile to be written.
#' @param outplot [character/link] Path to the output plot to be written.
#'
#' @param keep_ref [numeric] Number of alignments to keep or something. Plotting parameter.
#' @param plot_size [numeric] Plot size in inch.
#' @param outsd [character/link] Outputfile for the modified SD tsv file.
#' @return nothing. But output files written.
#'
#' @author Wolfram Höps
#' @export
make_chunked_minimap_alnment <-
  function(targetfasta,
           queryfasta,
           outpaf,
           #outplot,
           chunklen = 1000,
           keep_ref = 10000,
           minsdlen = 2000,
           plot_size = 10,
           saveplot = T,
           savepaf = T,
           quadrantsize = 100000,
           hllink = F,
           hltype = F,
           hlstart = NULL,
           hlend = NULL,
           targetrange = NULL,
           queryrange = NULL, 
           anntrack = NULL,
           x_seqname = NULL,
           x_start = NULL,
           x_end = NULL, 
           hltrack = NULL)
 {
    # Define intermediate files
    queryfasta_chunk = paste0(queryfasta, ".chunk.fa")
    outpaf_chunk = paste0(outpaf, '.chunk')
    outpaf_awk = paste0(outpaf, '.awked')
    outpaf_filter = paste0(outpaf, '.filter')
    outpaf_plot = paste0(outpaf, '.plot')
    outplot = paste0(outpaf, '.pdf')
    
    # Only partial? Cut down input fastas to a .tmp file
    if (!is.null(queryrange)) {
      shorten_fasta(targetfasta,
                    paste0(targetfasta, '.short.fa'),
                    targetrange)
      shorten_fasta(queryfasta, paste0(queryfasta, '.short.fa'), queryrange)
      
      targetfasta = paste0(targetfasta, '.short.fa')
      queryfasta =  paste0(queryfasta, '.short.fa')
    }
    # Run a series of chunking, aligning and merging functions/scripts
    # Single-sequence query fasta gets chopped into pieces.

    
    shred_seq(queryfasta, queryfasta_chunk, chunklen)
    print('1')
    print(queryfasta_chunk)
    # Self explanatory
    run_minimap2(targetfasta, queryfasta_chunk, outpaf_chunk)
    

    
    # Awk is used to correct the sequence names. This is because I know only there
    # how to use regex...
    awk_edit_paf(outpaf_chunk, outpaf_filter)
    # paf of fragmented paf gets put back together.
    compress_paf_fnct(inpaf_link = outpaf_filter, outpaf_link = outpaf, inparam_chunklen = chunklen)
    
    
    print('4')
    # Make a dotplot of that final paf (and with sd highlighting).
    miniplot = pafdotplot_make(
      outpaf,
      outplot,
      keep_ref = keep_ref,
      plot_size = plot_size,
      hllink = hllink,
      hltype = hltype,
      hlstart = hlstart, 
      hlend = hlend,
      minsdlen = minsdlen,
      save = saveplot,
      anntrack = anntrack,
      x_start = x_start, 
      x_end = x_end,
      x_seqname = x_seqname,
      hltrack = hltrack
    )
    print('5')
    if (saveplot == F) {
      print('returning your plot')
      return(miniplot)
    } else {
      print('servus')
      ggplot2::ggsave(
        filename = outplot,
        plot = miniplot,
        height = 10,
        width = 10,
        device = 'pdf'
      )
      print('Saving')
    }
    
  }

#' Chunkify query fasta
#'
#' @description This is a helperfunction calling an external script to
#' chop a query sequence into chunks.
#'
#' @param infasta [character/link] single-seq fasta to be chopped
#' @param outfasta_chunk [character/link] output chopped multi-seq fasta.
#' @param chunklen [numeric] length of sequence chunks in bp
#' @param scriptloc [character/link] link to shred.ss from bbmap.
#' @return nothing. Only output files written.
#'
#' @author Wolfram Höps
#' @export
shred_seq <- function(infasta,
                      outfasta_chunk,
                      chunklen) {
  scriptloc = query_config("shred")
  print(paste0(
    scriptloc,
    " in=",
    infasta,
    " out=",
    outfasta_chunk,
    " length=",
    chunklen
  ))
  system(
    paste0(
      scriptloc,
      " in=",
      infasta,
      " out=",
      outfasta_chunk,
      " length=",
      chunklen,
      " overwrite=true"
    )
  )
}

#' Submit a system command to run minimap2
#'
#' @description This is a helperfunction to run minimap2. Also check out:
#' https://github.com/PacificBiosciences/pbmm2/ . Minimap2 parameters:
#'  -k   k-mer size (no larger than 28). [-1]
#' -w   Minimizer window size. [-1]
#' -u   Disable homopolymer-compressed k-mer (compression is active for SUBREAD & UNROLLED presets).
#' -A   Matching score. [-1]
#' -B   Mismatch penalty. [-1]
#' -z   Z-drop score. [-1]
#' -Z   Z-drop inversion score. [-1]
#' -r   Bandwidth used in chaining and DP-based alignment. [-1]
#' -g   Stop chain enlongation if there are no minimizers in N bp. [-1]
#' #'
#' @param targetfasta [character/link] link to the 'target' single-sequence fasta (sometimes reference, e.g. chm13.)
#' @param queryfasta [character/link] link to the 'query' fasta. Can be single or multi-fasta
#' @param outpaf [character/link] Path to the output paffile to be written.
#' @param minimap2loc [character/link] link to minimap2 binary.

#' @return nothing. Only output files written.
#'
#' @author Wolfram Höps
#' @export
run_minimap2 <-
  function(targetfasta,
           queryfasta,
           outpaf,
           nthreads = 4) {
    #system(paste0(minimap2loc," -x asm20 -c -z400,50 -s 0 -M 0.2 -N 100 -P --hard-mask-level ", fastatarget, " ", fastaquery, " > ", outpaf))
    
    minimap2loc = query_config("minimap2")
    
    # Some self-defined parameters
    system(
      paste0(
        minimap2loc,
        " -x asm20 -P -c -s 0 -M 0.2 -t ",
        nthreads,
        " ",
        targetfasta,
        " ",
        queryfasta,
        " > ",
        outpaf
      )
    )
    # Check if that was successful. 
    stopifnot("Alignment error: Minimap2 has not reported any significant alignment. 
              Check if your input sequence is sufficiently long." = 
                file.size(outpaf) != 0)
    
    #pbmm2: CCS/HIFI
    #system(paste0(minimap2loc," -k 19 -w 10 -u -o 5 -O 56 -e 4 -E 1 -A 2 -B 5 -z 400 -Z 50 -r 2000 -L 0.5 -g 5000", targetfasta, " ", queryfasta, " > ", outpaf))
    
    # W, 23rd Dec 2021. Since the dev of pbmm2, the minimap2 parameters have changed. I adapted everything to the new notation.
    # the -L paramter (formerly Long join flank ratio) is no longer existing, so I'm leaving it out.
    #system(paste0(minimap2loc," -k 19 -w 10 -O 5,56 -E 4,1 -A 2 -B 5 -z 400,50 -r 2000 -g 5000 ", targetfasta, " ", queryfasta, " > ", outpaf))
    
    
  }


#' Submit a system command to run awk to change sequence chunk names
#'
#' @description This is a helperfunction to run awk
#'
#' @param inpaf [character/link] input paf
#' @param outpaf [character/link] output paf
#'
#' @return nothing. Only output files written.
#'
#' @author Wolfram Höps
#' @export
awk_edit_paf <- function(inpaf, outpaf) {
  print(inpaf)
  print(outpaf)
  
  scriptlink = query_config("awkscript")
  print(scriptlink)
  system(paste0(scriptlink, " ", inpaf, " ", outpaf))
}

#' Helperfunction to save a fasta file.
#'
#' @description a simple function that takes a data.frame that has a column name
#' and seq and writes a fasta file from it. Taken from
#' https://bootstrappers.umassmed.edu/guides/main/r_writeFasta.html.
#'
#' @param data [character/link] data frame with column 'name' and 'seq'
#' @param filename [character/link] output filename.
#'
#' @return nothing. Only output files written.
#'
#' @author Nicholas Hathaway
#' @export
writeFasta <- function(data, filename) {
  fastaLines = c()
  for (rowNum in 1:nrow(data)) {
    fastaLines = c(fastaLines, as.character(paste(">", data[rowNum, "name"], sep = "")))
    fastaLines = c(fastaLines, as.character(data[rowNum, "seq"]))
  }
  fileConn <- file(filename)
  writeLines(fastaLines, fileConn)
  close(fileConn)
}

#' helperfunction to shorten a fasta file.
#' @author Nicholas Hathaway
#' @export
shorten_fasta <- function(infasta, outfasta, range) {
  input = read.table(infasta)
  seq_shortened = as.character(Biostrings::subseq(
    Biostrings::readDNAStringSet(infasta),
    start = range[1],
    stop = range[2]
  ))
  
  writeFasta(data.frame(name = 'seq', seq = seq_shortened), filename = outfasta)
  
  print('Successfully written sub-fasta')
}


#' https://rdrr.io/cran/insect/src/R/complement.R
#' Reverse complement DNA in character string format.
#'
#' This function reverse complements a DNA sequence or vector of DNA
#'   sequences that are stored as character strings.
#'
#' @param z a vector of DNA sequences in upper case character string format.
#' @return a vector of DNA sequences as upper case character strings.
#' @details This function accepts only DNA sequences in concatenated character
#'   string format, see \code{\link[ape]{complement}} in the \code{\link[ape]{ape}}
#'   package for "DNAbin" input objects, and \code{\link[seqinr]{comp}} in the
#'   \code{\link[seqinr]{seqinr}} package for when the input object is a character
#'   vector.
#' @author Shaun Wilkinson
#' @examples rc("TATTG")
################################################################################
rc <- function(z) {
  rc1 <- function(zz) {
    s <- strsplit(zz, split = "")[[1]]
    s <- rev(s)
    dchars <- strsplit("ACGTMRWSYKVHDBNI", split = "")[[1]]
    comps <- strsplit("TGCAKYWSRMBDHVNI", split = "")[[1]]
    s <- s[s %in% dchars] # remove spaces etc
    s <- dchars[match(s, comps)]
    s <- paste0(s, collapse = "")
    return(s)
  }
  z <- toupper(z)
  tmpnames <- names(z)
  res <- unname(sapply(z, rc1))
  if (!is.null(attr(z, "quality"))) {
    strev <-
      function(x)
        sapply(lapply(lapply(unname(x), charToRaw), rev), rawToChar)
    attr(res, "quality") <-
      unname(sapply(attr(z, "quality"), strev))
  }
  names(res) <- tmpnames
  return(res)
}
################################################################################

#' Create a simple random sequence.
#'
#' @description Simple function to create a random string of ACGT.
#'
#' @param n [numeric] length of desired sequence (bp)
#' @param gcfreq [character/link] desired GC frequency.
#' @return A character vector of a random DNA sequence.
#'
#' @author Wolfram Höps
#' @export
randDNASeq <- function(n, gcfreq, seed = 1234) {
  bases = c('A', 'C', 'G', 'T')
  
  set.seed(seed)
  seq = sample(bases,
               n,
               replace = T,
               prob = c((1 - gcfreq) / 2, gcfreq / 2, gcfreq / 2, (1 - gcfreq) /
                          2))
  return(paste(seq, collapse = ''))
}



wrapper_dotplot_with_alignment <-
  function(seqname,
           start,
           end,
           genome_x_fa,
           genome_y_fa,
           limitfasta_x,
           limitfasta_y,
           outpaf_link,
           chunklen = 1000) {
    extract_subseq(genome_x_fa, seqname, start, end, limitfasta_x)
    plot = make_chunked_minimap_alnment(
      genome_y_fa,
      limitfasta_x,
      outpaf_link,
      chunklen = 1000,
      minsdlen = 2000,
      saveplot = F,
      hllink = F,
      hltype = F,
      wholegenome = T
    )
    return(plot)
    
  }


#' General purpose wrapper
#'
#' @description Simple function to create a random string of ACGT.
#'
#' @param n [numeric] length of desired sequence (bp)
#' @param gcfreq [character/link] desired GC frequency.
#' @return A character vector of a random DNA sequence.
#'
#' @author Wolfram Höps
#' @export
wrapper_dotplot_with_alignment_fast <-
  function(seqname,
           start,
           end,
           genome_x_fa,
           genome_y_fa,
           subseqfasta_x,
           subseqfasta_y,
           conversionpaf_link,
           outpaf_link,
           chunklen = 10000,
           factor = 0.5) {
    # Get coords in assembly
    coords_liftover = liftover_coarse(seqname, start, end, conversionpaf_link, lenfactor = 1)
    
    # Gimme fasta
    extract_subseq_bedtools(genome_x_fa, seqname, start, end, subseqfasta_x)
    extract_subseq_bedtools(
      genome_y_fa,
      coords_liftover$lift_contig,
      coords_liftover$lift_start,
      coords_liftover$lift_end,
      subseqfasta_y
    )
    print("##############################")
    #outpaf_link = as.character(runif(1,1e10, 1e11))
    plot = make_chunked_minimap_alnment(
      subseqfasta_x,
      subseqfasta_y,
      outpaf_link,
      chunklen = chunklen,
      minsdlen = 2000,
      saveplot = T,
      hllink = F,
      hltype = F,
      wholegenome = F
    )
    return(plot)
    
  }



#' ColMax function
#'
#' From Stackoverflow. Does what you expect it to do.
#' @export
colMax <- function(data)
  sapply(data, max, na.rm = TRUE)


# Hi we are in a feature adding branch.
