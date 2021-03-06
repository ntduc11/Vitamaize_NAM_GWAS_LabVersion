rm(list = ls())

#Use the multtest library to obtain FDR-adjusted P-values

###Required files:
### (1) imputedMarkers.allchr.0.1cm.final.Panzea.consolidated.B.txt (GBS SNPs)
### (2) candidate gene list (see sample)
### (3) transformed BLUEs
### (4) JL model output, with NA in pop term row (modified version) and residual row removed
### (5) Marker effect estimates from script 1b


setwd("/Users/anybody/Documents/Toco_NAM/")
home.dir <- getwd()
geno.path = paste(home.dir, "/Geno.Pheno_Inputs/",sep='')
pheno.path = paste(home.dir, "/Geno.Pheno_Inputs/",sep='')
dT3.pheno.path = paste(home.dir,"/Methods/dT3_removeExtremeVal_test/Box-Cox_TRANS_filesforjlremoveextremeval_dt3/",sep='')
dT3.popByMarker.path = paste(home.dir,"/Methods/dT3_removeExtremeVal_test/new.trans_new.perm_FINAL/",sep='')
PVE.byFamily = TRUE #this method calculates PVE based on allele frequencies within family as developed by Peter Bradbury and Christine Diepenbrock; signs are also included (both of these updates are reflected in output file suffix)
popByMarker.path = paste(home.dir,"/JL/Allelic_Effect_Estimates.no.MultiColl/",sep='')
JL.path = paste(home.dir,"/JL/Toco_FinalModels_postMCCorrPostRescan/",sep='')
#PVEvalidat.path = paste(home.dir, "/validate_CBK.AEL/CHD_Tassel3fromSF_modified0.01/PVE_Documentation_and_Validation/",  sep = "")
tabSummary.path = paste(home.dir,"/Summary_Tables.Figures/",sep='')
BLUE.or.BLUP <- "BLUE"  #Options are "BLUE" and "BLUP"
trait.set = "tocos"
test <- FALSE #Options are TRUE and FALSE

#Read in the gneotypic data
genotypes <- read.table(paste(geno.path,"imputedMarkers.allchr.0.1cm.final.Panzea.consolidated.B.txt",sep=''), head = TRUE)

candidate.gene.list <- read.table("/Users/anybody/Desktop/Tocochromanol_Candidate_Gene_List_GRZMs_R.formatted_updated.for.NAM.txt", head = TRUE,stringsAsFactors=FALSE)
trait <- c("aT","aT3","dT","dT3","gT","gT3","PC8","totalT","totalT3","totalTocochrs")       #CHD added 5-11
trait.collinear <- c("aT3","dT3","gT3","totalT3","totalTocochrs")

pop.seq <- as.data.frame(as.factor(c("01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12", "13",
                                    "14", "15", "16", "18", "19", "20", "21", "22", "23", "24", "25", "26")))
founder.names <- as.data.frame(c("B97", "CML103", "CML228", "CML247", "CML277", "CML322", "CML333", "CML52", 
                                 "CML69", "Hp301", "Il14H", "Ki11", "Ki3", "Ky21", "M162W", "M37W", "Mo18W", 
                                 "MS71", "NC350", "NC358", "Oh43", "Oh7B", "P39", "Tx303", "Tzi8"))
NAM.pops <- cbind(pop.seq, founder.names)
colnames(NAM.pops) <- c("Pop.num", "Pop.Founders")

Results <- NULL
for(i in trait){
  if(i == "dT3"){
  TASSEL.model.results <- read.table(paste(JL.path,"JL_fromTrans_dT3_Redone_MC.corrected_Tassel3fromSF_forR.txt", sep = "") , head = TRUE,stringsAsFactors = FALSE)       
  }else if (i %in% trait.collinear){   
    print("dT3 went here...oops.")
    TASSEL.model.results <- read.table(paste(JL.path,"MC_corrected_",i,"_postRescan_R.formatted.txt", sep = "") , head = TRUE,stringsAsFactors = FALSE)        #CHD added loop 5-14 to handle both MC and non-MC traits
  } else {
    TASSEL.model.results <- read.table(paste(JL.path,i,"_model_3fromSF_0.01_Final_R.formatted.txt", sep = "") , head = TRUE,stringsAsFactors = FALSE)
  }
  
  if(is.numeric(TASSEL.model.results[,2]) == FALSE){
    print(paste("The chromosome column in ", i," model results needs to be numeric. Please change this before proceeding.", sep = ""))
    break;
  }

  #Obtain corresponding physical bp positions of the support intervals
  #I am going to use a for loop so that all SNPs on the same chromosome are isolated. This will prevent selecting a SNP on a different chromosome with the same genetic position.
  support.int.physical <- matrix(NA, nrow = nrow(TASSEL.model.results)-1,ncol = 2)
  #will leave first row as NA to correspond to the pop term
  for(j in 2:nrow(TASSEL.model.results)){
  this.chr = TASSEL.model.results[j,2]
   geno.chr <- genotypes[which(genotypes[,3] == this.chr),1:5] 
   geno.chr[,4] = as.numeric(geno.chr[,4])
   geno.chr[,5] = as.numeric(geno.chr[,5])
   support.int.physical[j-1,1] <- geno.chr[which(round(geno.chr[,5],1) == round(TASSEL.model.results[j,11],1)), 4]
   support.int.physical[j-1,2] <- geno.chr[which(round(geno.chr[,5],1) == round(TASSEL.model.results[j,12],1)), 4]
   }
    
  #Determine if any of the 60 candidate genes are in the support intervals
  cand.gene <- rep(NA, nrow(support.int.physical))

  for(m in 1:nrow(support.int.physical)){
   cand.chr <- candidate.gene.list[which(candidate.gene.list[,4] == TASSEL.model.results[m+1,2]),] 
   cand.chr[,5] = as.numeric(cand.chr[,5])
   cand.chr[,6] = as.numeric(cand.chr[,6])
   #print(cand.chr)
   cand.gene.names = NULL
   cand.gene.names <- cand.chr[ which(( (cand.chr[,5] > (support.int.physical[m,1])) & (cand.chr[,6] < (support.int.physical[m,2])) ) |  
             ( (cand.chr[,5] < (support.int.physical[m,1])) & (cand.chr[,6] > (support.int.physical[m,1]))  ) |
             ( (cand.chr[,5] < (support.int.physical[m,2])) & (cand.chr[,6] > (support.int.physical[m,2])) ) ), 3]
   genes.identified <- NULL
   for(k in 1:length(cand.gene.names)){genes.identified <- paste(genes.identified,", ", cand.gene.names[k], sep = "")}
   
   cand.gene[m] <- genes.identified 
      }

   ########################## Calculate PVE
  #### Read in the phenotypic data, and merge it to the genotypic data
  #setwd(paste(home.dir, "\\(9)JL Analysis\\Permutations\\Phenotypes\\Phen_files_no_trait_prefix\\",  sep = ""))
  if(i == "dT3"){
    pheno.data = read.table(paste(dT3.pheno.path,"BLUEs_No_Outliers_Transformed_dT3.only.Redone.txt",sep=''),head=TRUE,stringsAsFactors=FALSE)
    pheno.data$dT3 = as.numeric(pheno.data$dT3)
  }else{
    pheno.data = read.table(paste(pheno.path,"BLUEs_No_Outliers_Transformed_all_for_TASSEL_",i,".txt", sep = ""), head = TRUE)
  }
  
  geno.reduced <- genotypes[which(genotypes[,1] %in% TASSEL.model.results[,4]),-c(2:5)]
  geno.reduced.formatted <-as.data.frame(t(geno.reduced[,-1]))
  colnames(geno.reduced.formatted) <- as.character(t(geno.reduced[,1]))

  #pheno.data will always have more data becuase IBM is included in the phenotypic data.
  colnames(pheno.data)[1] = "Geno_Code"
  geno.and.pheno <- merge(pheno.data, geno.reduced.formatted, by.x = "Geno_Code", by.y = "row.names")

  #Add a population column
  geno.and.pheno <- cbind(geno.and.pheno[,1], as.factor(substr(as.character(geno.and.pheno[,1]), start = 3, stop = 4)), geno.and.pheno[,c(2:ncol(geno.and.pheno))])
  colnames(geno.and.pheno)[2] <- "pop"

  ####Extract the trait value, RIL ID, and family
  pheno.data.temp <- geno.and.pheno[,1:3]
  
  #Remove all missing phenotypic data
  
  if(length(which(is.na(pheno.data.temp[,3])))>0) pheno.data.temp <- pheno.data.temp[-which(is.na(pheno.data.temp[,3])),]
  
  #For validation. 
  if(test == TRUE){
    #setwd(paste(home.dir, "\\PVE_Documentation_and_Validation\\",  sep = ""))  #CHD moved up top 5-14
    write.table(pheno.data.temp, paste(PVEvalidat.path,"Pheno.data.temp.", i,".txt", sep = ""), sep = "\t", row.names = FALSE, quote = FALSE)
  }
  
  ####Calculate the following summary statistics: 
  #Variance within each family

  Vf.vector <- as.vector(tapply(pheno.data.temp[,3], pheno.data.temp[,2], var))

  #Sample size within each family
  nf.vector <- as.vector(tapply(pheno.data.temp[,3], pheno.data.temp[,2], length))
  
  #Overall sample size
  N <- sum(nf.vector)
  nf.vector.by.N <- nf.vector/N
 
  den <- (1/N)*crossprod(nf.vector, Vf.vector)

  #Read in the marker data
  if(i == 'dT3'){
  pop.by.marker.effects <-  read.table(paste(dT3.popByMarker.path,"Pop.by.Marker.Effect.Estimates.from.R.dT3_Redone.SI01.txt", sep = ""), sep = "\t", head = TRUE)
  }else{
    pop.by.marker.effects <-  read.table(paste(popByMarker.path,"Pop.by.Marker.Effect.Estimates.from.R.",i,".SI01.txt", sep = ''),sep='\t',head=TRUE)
  }

  #Separate out the pop and maker terms and append them to "pop.by.marker.effects"
  pop.term <- as.factor(substr(as.character(pop.by.marker.effects[,1]), start = 4, stop = 5))
  marker.term <-  as.factor(substr(as.character(pop.by.marker.effects[,1]), start = 7, stop = nchar(as.character(pop.by.marker.effects[,1]))))
  
  pop.by.marker.effects <- cbind(pop.term, marker.term, pop.by.marker.effects)
  
  #This following sequence is used to figure out which family has no pop*marker effect estimate (this arises when the heritabilities are zero)
  pop.seq <- as.data.frame(as.factor(c("01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12", "13",
                         "14", "15", "16", "18", "19", "20", "21", "22", "23", "24", "25", "26")))
  
  colnames(pop.seq)[1] <- "Pop"
  
  #Set a PVE results vector to NULL
  PVE.results <- NULL
  print(i)
  maf_allMarkers = NULL
  pooledmaf_allMarkers = NULL
  #For loop using j as an index
  for(j in unique(pop.by.marker.effects[,2])){
    #Extract the corresponding additive effect estimates 
    additive.effects <- pop.by.marker.effects[which(pop.by.marker.effects[,2] == j), c(1,2,4)]
    
    #For validation
    if(test == TRUE){
      #setwd(paste(home.dir, "\\PVE_Documentation_and_Validation\\",  sep = ""))
      write.table(additive.effects, paste(PVEvalidat.path,"Additive.effects.temp.", i,".txt", sep = ""), sep = "\t", row.names = FALSE, quote = FALSE)
    }
  
    if(nrow(additive.effects) != 25){
     print("There were fewer than 25 rows in additive effects.")
     #Objective: Put nf.vector, Vf.vector into a matrix, and then merge it with the additve effect estimates
     vectors <- as.data.frame(cbind(pop.seq, nf.vector, Vf.vector))    
     add.and.vectors <- merge(additive.effects, vectors, by.x = "pop.term", by.y = "Pop")
      
     #Now the nf.vectora nd Vf.vector will not have the populations with no additive effect estimates
     nf.vector.temp <- add.and.vectors[ ,4]
     Vf.vector.temp <- add.and.vectors[ ,5]    
     
     a.sq <- additive.effects[,3]^2
     num.left.term  <- ((2/N)*(crossprod(nf.vector.temp,a.sq)))
     
     num.right.term <- ((1/N)*(crossprod(nf.vector.temp,additive.effects[,3])))^2
    
     num <- num.left.term - num.right.term

     N.temp <- sum(nf.vector.temp)
 
     den <- (1/N.temp)*crossprod(nf.vector.temp, Vf.vector.temp)

     PVE.marker <- c(j, (num/den))

    }else{
      if (PVE.byFamily == FALSE){
        sq.term <- additive.effects[,3]^2
        num.left.term  <- ((2/N)*(crossprod(nf.vector,sq.term)))
        num.right.term <- ((1/N)*(crossprod(nf.vector,marker.effects[,1])))^2
        num <- num.left.term - num.right.term
        PVE.by.term <- num/den
        PVE.marker <- c(j, (num/den))
      }else if (PVE.byFamily == TRUE){
        #Genotype scores within each family--added by CHD 6/4/2015, for new Bradbury PVE calculation that accounts for sampling variation (allele freqs not always = 0.5)
        colnames(geno.and.pheno)[1] = "Taxa"
        thisGeno.with.Taxa = geno.and.pheno[c("Taxa",j)]
        print(j)
        genoScores = merge(pheno.data.temp,thisGeno.with.Taxa,by.x=1,by.y = 1) #append the genos just for this marker to line,pop,pheno cols 
        
        #Only to see which MAFs are closest to 0.5 (for comparison to previous PVE calcs)
        minor.counts.vector = as.vector(tapply(genoScores[,4], genoScores[,2],function(scoreSet){
          s=as.numeric(scoreSet)
          #return(1*length(which(s<=0.5 & s<1.5)+2*length(which(s>=1.5 & s<=2)))) #includes distance-imputed
          return(1*length(which(s==1)+2*length(which(s==2))))
        }))
        maf = minor.counts.vector/(2*nf.vector)
        if(length(which(maf >= 0.5))>0){print("Error: minor allele frequency >= 0.5")}
        maf_allMarkers = rbind(maf_allMarkers,maf)
        pooled_maf = (1/N)*crossprod(nf.vector, maf)
        pooledmaf_allMarkers = c(pooledmaf_allMarkers,pooled_maf)
        
        #actual PVE calculation
        genoScores[,4] = genoScores[,4] - 1 #need to have -1,0,1 coding so that homozyg minor allele has effect of -n
        pop.a = additive.effects[,c(1,3)]
        genoScores.by.Effects.vector = genoScores[,4]
        for (this.pop in unlist(pop.seq)){
          #print(this.pop)
          a = pop.a[which(pop.a[,1]==this.pop),2]
          for (this.row in 1:nrow(genoScores)){
            #calculate additive effect * marker score, *-1 because effect estimate  (including sign) is for B73 reference allele, which is now coded as -1
            if(genoScores[this.row,2]==this.pop){genoScores.by.Effects.vector[this.row]=-1*a*genoScores.by.Effects.vector[this.row]}
          }
        }
        pop_Scores.by.Effects = cbind(genoScores[,2],genoScores.by.Effects.vector)
        Vg.vector = tapply(pop_Scores.by.Effects[,2],pop_Scores.by.Effects[,1],var)
        Vg.den <- (1/N)*crossprod(nf.vector, Vg.vector) 
        PVE.marker <- c(j, (Vg.den/den))
      } 
     }
    #Append each result. Note that the name of the marker MUST be included as well. 
    PVE.results <- rbind(PVE.results,  PVE.marker)
       
  } #End for(j in unique(pop.by.marker.effects[,2]))
  
  maf.to.print=cbind(maf_allMarkers,as.vector(pooledmaf_allMarkers))
  rownames(maf.to.print)=as.character(unique(pop.by.marker.effects[,2]))
  colnames(maf.to.print)=c(unlist(pop.seq),"Pooled")
  write.table(maf.to.print,paste(dT3.popByMarker.path,"AlternateAlleleFrequencies_byFamily_dT3.redo_newTrans.txt", sep=''),col.names = TRUE)
  
  ########################### End Calculate PVE 
  
  #################################Determine the number of QTL in each family, and which families have the QTL
  number.of.familes.with.QTL <- NULL
  specific.families.with.QTL <- NULL
  for(j in unique(marker.term)){
    print(j)
    #Obtain a subset of pop.by.marker.effects for the jth QTL only
    pop.by.marker.effects.subset1 <- pop.by.marker.effects[which(marker.term == j),]
    pop.term.subset1 <- pop.term[which(marker.term == j)]
    
    #Obtain a second subset of the pop.by.marker that are statistically significant at 5% FDR. These will be
    pop.by.marker.effects.subset2 <- pop.by.marker.effects.subset1[which(pop.by.marker.effects.subset1[,ncol(pop.by.marker.effects.subset1)] <= 0.05),]
    pop.term.subset2 <- pop.term.subset1[which(pop.by.marker.effects.subset1[,ncol(pop.by.marker.effects.subset1)] <= 0.05)]
    print(cbind(pop.by.marker.effects.subset2[,ncol(pop.by.marker.effects.subset2)],pop.term.subset2))
    
    #Count the number of families that have the QTL
    number.of.familes.with.QTL <- c(number.of.familes.with.QTL, length(pop.term.subset2))
    
    #Identify the families that have the QTL
    as.data.frame(NAM.pops)
    as.data.frame(pop.term.subset2)
    families.with.QTL <- merge(as.data.frame(pop.term.subset2), as.data.frame(NAM.pops), by.x = "pop.term.subset2",
                               by.y = "Pop.num")
    families.with.QTL.as.string <- NULL
    for(k in 1:nrow(families.with.QTL)) families.with.QTL.as.string <- paste(families.with.QTL.as.string,",",families.with.QTL[k,2])
    specific.families.with.QTL <- c(specific.families.with.QTL, families.with.QTL.as.string)
    
  }#end for(i in unique(marker.term))
  
  #########################End of "Determine the number of QTL in Each family"
  
  #Make sure you have the following information: Name of Marker, peak physical position, support interval, P-value, PVE, Candidate genes in suppoprt interval

  results.trait <- cbind(TASSEL.model.results[-1,c(1,2)],  substr(as.character(TASSEL.model.results[-1,4]), start = 3, stop = nchar(as.character(TASSEL.model.results[-1,4]))), support.int.physical,
                         TASSEL.model.results[-1,c(4,9)], PVE.results[,2],cand.gene, number.of.familes.with.QTL, specific.families.with.QTL) 
      
  #Append these results to the results file
  Results <<- rbind(Results, results.trait)

}# End for(i in trait)

setwd(home.dir)                                                                                                                                                                              

#Add headers to the Results
colnames(Results) <- c("Trait", "Chr", "Peak_Position", "Supp_Int_Left", "Supp_Int_Right", "Peak_Marker_Name", "P-value", "PVE", "Candidate_Gene_in_Support_Interval", "Number_of_Families_with_QTL", "Families_with_QTL")

#Write the results into a table
write.table(Results, paste(tabSummary.path,"Tabular_Summary_of_JL_",trait.set,"_Results_for_all_traits_SI01_newPVEv2_corrsigns.txt", sep = ""), sep = "\t", row.names = FALSE, quote = FALSE) 
#write.table(Results, paste(tabSummary.path,"Tabular_Summary_of_JL_",trait.set,"_Results_for_all_traits_SI01_newPVEv2_corrsigns_dT3_Redone.txt", sep = ""), sep = "\t", row.names = FALSE, quote = FALSE) #for dT3 redo