#!/usr/local/bin/Rscript

# Give parameters, and this script makes an instructions bedfile
# for creating a sequence of choice with seqbuilder.

# runs only when script is run by itself
if (sys.nframe() == 0){

  option_list = list(
    optparse::make_option(c("-t", "--seqlen"), type="numeric", default=NULL,
                help="Total sequence length [bp]", metavar="numeric"),
    optparse::make_option(c("-s", "--sdlen"), type="numeric", default=NULL,
                help="length of sds", metavar="numeric"),
    optparse::make_option(c("-d", "--inner_sd_dist"), type="numeric", default=NULL,
                help="distance between the two paris of an SD", metavar="numeric"),
    optparse::make_option(c("-i", "--inter_sd_dist"), type="numeric", default=NULL, 
                help="distance between one pair and its neighbour", metavar="numeric"),
    optparse::make_option(c("-m", "--fracmatch"), type="numeric", default=NULL, 
                help="SD similarity", metavar="numeric"),
    optparse::make_option(c("-r", "--strand"), type="character", default=NULL, 
                help="strand", metavar="character"),
    optparse::make_option(c("-o", "--outfile"), type="character", default=NULL, 
                help="Length of chunks to use for minimap2", metavar="character")
    
  )
  
  
  debug=F
  if (debug){
    opt = list()
    opt$seqlen = 10000
    opt$distance = 100
    opt$sdlen = 500
    opt$inter_sd_len = 500
  }
  
  options(error=traceback)
  
  parser <- optparse::OptionParser(usage = "%prog -i alignments.coords -o out [options]",option_list=option_list)
  opt = optparse::parse_args(parser)
  print(opt)
  colnames_bed = c('chrom','chromStart',
                        'chromEnd', 'uid', 'otherChrom',
                        'otherStart','otherEnd', 'strand', 'fracMatch')
  
  n_sds = floor(opt$seqlen / ((opt$sdlen*2) + opt$inner_sd_dist + opt$inter_sd_dist))
  contig = "simcontig"
  chromStart = (0:(n_sds-1)) * ((opt$sdlen * 2) + opt$inner_sd_dist + opt$inter_sd_dist)
  chromEnd = chromStart + opt$sdlen
  otherStart = chromEnd + opt$inter_sd_dist
  otherEnd = otherStart + opt$sdlen
  uid = paste0("SD", 1:n_sds)
  
  sds = data.frame('chrom' = contig, 
                       'chromStart' = chromStart,
                       'chromEnd' = chromEnd, 
                       'uid' = uid, 
                       'otherChrom' = contig,
                       'otherStart' = otherStart, 
                       'otherEnd' = otherEnd, 
                       'strand' = opt$strand,
                       'fracmatch' = opt$fracmatch)
  
  
  
  write.table(sds, file=opt$outfile, sep='\t', row.names=F, col.names=F, quote=F)
}
