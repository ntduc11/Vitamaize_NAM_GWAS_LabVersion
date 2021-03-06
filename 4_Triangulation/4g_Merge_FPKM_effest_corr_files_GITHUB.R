rm(list = ls())

#inputs
setwd("/Users/anybody/Documents/Toco_NAM/")
home.dir <- getwd()
correlation.output.dir <- "/Expression_Analyses/GMMS3.1Results_tocos/corrsFrom5.3/"
location.of.raw.P.value.results <- correlation.output.dir    #also in specific trait folder
location.of.FDR.P.value.results = correlation.output.dir
proximal.genes.dir <- "/Expression_Analyses/Tri_Summaries/ProximalGenes/"
dir.for.compil.of.tri.summ = correlation.output.dir
tabSummary.path = "/Tabular_Summaries/"
location.of.GWAS.results = "/GWAS_Analysis/GWAS_25fam_HMPonly_TASSEL3_alpha01_2015_corr/"
column.of.cSI.in.tab.sum <- 14
column.of.peak.marker.in.tab.sum <- 6
column.of.trait.in.tab.sum <- 1
trait.col.common.key <- 1
chr.col.common.key <- 2
pos.col.common.key <- 3
  
#Read in the tabular summary; used below to obtain a list of trait names
tabular.summary <- read.table(paste(home.dir,tabSummary.path,"Tab_Sum_tocos_alpha.01_SI_with_GWAS_SNPs_common_SI_20150511_recsuppregions_LODscores.txt", sep = ""), head = TRUE)

absolute.final.data.set.FPKM <- read.table(paste(home.dir,FPKM.file.dir,"FPKM.table.by.gene.ann.complete.matrix.FPKMthreshold.1_filter.by.kernel_across_all.samples.log2trans.txt", sep = ""), head = TRUE)
traits <- as.vector(unique(tabular.summary[,column.of.trait.in.tab.sum]))

###########################################combine FPKM,SNP output across multiple traits

#For loop through each common S.I.; Specify tri folder
for(cSI in unique(tabular.summary[,column.of.cSI.in.tab.sum])){
  print(paste("For common support interval number ",cSI,":",sep=''))
  
    #Change dir to master output dir for this common S.I.; final files from this script will be placed here.
    setwd(paste(home.dir,dir.for.compil.of.tri.summ,"QTL_",cSI,"_imputed.ordered.tri.files", sep=''))

    #obtain all FPKM.SNP correlation files from specified folder
     file.list <- list.files(getwd())
     FPKM.effest.files <- file.list[grep("ORDERED", file.list)]
     print(FPKM.effest.files)
    
    initialize.data.frame <- NULL
       
    #read in FPKM, SNP files, one at a time
    for(pick.one in 1:length(FPKM.effest.files)){
            data.file <- read.table(FPKM.effest.files[pick.one], head = TRUE, stringsAsFactors=F)

            ######NOTE TO CHD: the following line will pick up an entire or truncated trait name and associate closest version to that in trait vector
            ######I was attempting to figure out how this would work for your traits, using shortest trait names as examples
            ######Best would be to set substr stop to be start + 3, so that dt is represented as "dt_#" and dt3 "dt3_"
            ######This should work
            pattern <- substr(FPKM.effest.files[pick.one], 26, 29)
            trait.name <- grep(pattern, traits, value = TRUE)

         #some housekeeping
            #remove extraneous correlation row
            #data.file <- data.file[-1,]
         
            #add trait name to each column name
            colname.vector <- colnames(data.file)[5:ncol(data.file)]
            new.colname.vector <- paste(trait.name, "_", colname.vector, sep = "")
            colnames(data.file)[5:ncol(data.file)] <- new.colname.vector

            #generate columns for gene start and stop positions
            #suffix.vector <- c("_12_DAP", "_16_DAP", "_20_DAP", "_24_DAP", "_30_DAP", "_36_DAP", "_root", "_shoot")
            #gene.vector.remove.suffix <- as.vector(mapply(sub, suffix.vector, "" , data.file[,1]))
            #positional.data <- absolute.final.data.set.FPKM[absolute.final.data.set.FPKM[,1] %in% gene.vector.remove.suffix, c(1,4:5)]

            #pos.for.file <- NULL
            #for (i in gene.vector.remove.suffix){
            #hold.data <- positional.data[which(positional.data[,1] == i), ]
            #pos.for.file <- rbind(pos.for.file, hold.data)
            #} # end i loop

            #add positional data to data.file
            #new.data.file <- cbind(data.file[,1], pos.for.file, data.file[,2:ncol(data.file)] , stringsAsFactors=F)
            #colnames(new.data.file)[1] <- colnames(data.file)[1]

            #ensure data file is sorted by gene start position
            new.data.file <- data.file
            new.data.file <- new.data.file[order(new.data.file[,3]),]
            
            if((pick.one == 1) && (length(FPKM.effest.files) == 1)) {                 
              new.data.file -> start.list.mod}else{
        
                    #initialize search
                    if(pick.one == 1){
                      new.data.file -> initialize.data.frame    #setup with previous data in line 166
                      next
                      }else{
                      new.data.file -> query.data.frame#}       opened loop to include code up to line 168
        
                           #identify minimum genomic position in both data sets
                           min.initial <- min(initialize.data.frame[,3], na.rm = TRUE)  #ADDRESS no NAs allowed to be considered in min
                           min.query <-  min(query.data.frame[,3])
        
                           #set data set with minimum genomic position as starting list
                           if(min.initial <= min.query){
                           start.list <- initialize.data.frame
                           query.list <- query.data.frame}else{
                           start.list <- query.data.frame
                           query.list <- initialize.data.frame}
                           
                           #identify number of SNPs in each of two lists
                           #samples.in.start.list <- ncol(start.list)-4 # 4 columns with identity information
                           #samples.in.query.list <- ncol(query.list)-4 # 4 columns with identity information
        
                           #add placeholders for all possible rows to start.list in order to accomodate query.list
                           start.row.matrix <- as.data.frame(matrix(NA, nrow=nrow(query.list), ncol=ncol(start.list)))
                           colnames(start.row.matrix) <- colnames(start.list)
                           start.list.mod <- rbind(start.list, start.row.matrix)
                           start.NA.row <- nrow(start.list)+1
                           
                           start.col.matrix <- as.data.frame(matrix(NA, nrow=nrow(start.list.mod), ncol=ncol(query.list)))
                           colnames(start.col.matrix) <- colnames(query.list)
                           start.list.mod <- cbind(start.list.mod, start.col.matrix)
                           rownames(start.list.mod) <- NULL
                           start.NA.col <-  ncol(start.list)+1
                           
                           rownames(query.list) <- NULL
                           
                           #start loop to match rows from query list with those from start.list.mod
                           non.matched.rows <- NULL
                           
                          for (n in 1:nrow(query.list)){
                              if((query.list[n,1] %in% start.list.mod[,1]) == FALSE){                 
        
                                non.matched.rows <- rbind(non.matched.rows, query.list[n,])}else{
                                
                                row.of.interest <- rownames(start.list.mod[which(query.list[n,1] == start.list.mod[,1]),])
                                start.list.mod[row.of.interest,start.NA.col:ncol(start.list.mod)] <- query.list[n,]
                                }
                                                       
                           } #end scanning n rows in query list
        
                           #if there are FPKM*sample rows from query list that do not match start list, add them to the bottom of the start list
                           #if((nrow(non.matched.rows)>0) == TRUE){
                           if(length(nrow(non.matched.rows)) == 0){break}else{  
                              rows.needed <- nrow(non.matched.rows)
                              start.list.mod[start.NA.row:(start.NA.row+rows.needed-1),start.NA.col:ncol(start.list.mod)] <- non.matched.rows
                              
                              #move sample identity information from non-matched rows up to first 4 columns to facilitate sorting
                              start.list.mod[start.NA.row:(start.NA.row+rows.needed-1), 1:4] <- non.matched.rows[,1:4]
                           
                           } #end non.matched.rows
        
             #more housekeeping
                #sort data by gene start to reorient entire data matrix
                start.list.mod <- start.list.mod[order(start.list.mod[,3]),]
                
                #remove rows complete with NA from data matrix
                start.list.mod <- start.list.mod[!(is.na(start.list.mod[,1]) == TRUE),]
                
                #remove original columns listing query row identity
                #start.list.mod <- start.list.mod[,-c((ncol(start.list.mod)-samples.in.query.list-3):(ncol(start.list.mod)-samples.in.query.list))]
        
                #seed initial data frame with revamped start list
                initialize.data.frame <- start.list.mod
                
                } #end new query
              } #end search loop for more than one trait in cSI    
             } #end pick.one file loop
        
        #call final data set again
        initialize.data.frame <- start.list.mod
        
        #remove rows complete with NA from data matrix
        initialize.data.frame <- initialize.data.frame[!(is.na(initialize.data.frame[,1]) == TRUE),]
        
        #remove columns with query row identity
            all.columns.to.be.removed <- NULL
            
            #recognize partial strings in subset of columns - excluding first four columns in order to retain them
            for(header.ID in c("gene_locus", "description", "left", "right")){
                remove.these.columns <- grep(header.ID, colnames(initialize.data.frame[5:ncol(initialize.data.frame)]))
                all.columns.to.be.removed <- c(all.columns.to.be.removed, remove.these.columns)
            }
            
            #add condition in the case where there was only one trait
            if(length(all.columns.to.be.removed) > 0){
                #add correct number of columns back to all.columns.to.be.removed, accounting for the first 4 that were excluded from string recognition loop
                all.columns.to.be.removed.mod <- all.columns.to.be.removed + 4
                
                #remove extraneous columns
                initialize.data.frame <- initialize.data.frame[,-all.columns.to.be.removed.mod]
            } # end removing columns
            
            
        #round correlations to three digits
        initialize.data.frame[,5:ncol(initialize.data.frame)] = round(initialize.data.frame[,5:ncol(initialize.data.frame)],3)
        
        #change all NAs to "." to facilitate reading matrix in excel
        initialize.data.frame[is.na(initialize.data.frame)] = "."
        
        #output table
        write.table(initialize.data.frame, paste("All.trait.FPKM.by.EffectEst.corr.summary.file.for.cSI.",cSI,".txt", sep = ""),  sep = "\t", quote = FALSE, row.names = FALSE)
        print(paste("Finished with common support interval number ",cSI,":",sep=''))   
} #end cSI loop