args <- commandArgs(trailingOnly = TRUE)
outfile=cc(gsub("\\.map.*$","",args[1]),".Rdata")
chrom=strsplit(args[1],"[,\\.]")[[1]][2]

dd=read.delim((args[1]))

save(dd,file=outfile,compress=T)

