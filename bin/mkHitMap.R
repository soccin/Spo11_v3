args <- commandArgs(trailingOnly = TRUE)
INFILE=args[1]

load(INFILE)
hits5p=dd$start
hits=data.frame(table(hits5p))
hits$hits5p=as.numeric(as.character(hits$hits5p))
colnames(hits)=c("pos","hits5p")
OUTFILE=cc(gsub("\\.map.*$","",INFILE),"HitMap5pA.Rdata")
save(hits,file=OUTFILE,compress=T)

