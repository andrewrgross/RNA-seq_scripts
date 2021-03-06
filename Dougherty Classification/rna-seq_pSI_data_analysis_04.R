### Tissues Specific Expression Analysis, Andrew R Gross, 2016-08-26
### Using a package developed by the Dougherty lab, calculate the uniqueness of a set of genes and the probability
### of another set containing those genes.

########################################################################
### Header
########################################################################
library(pSI)
load("C:/Users/grossar/Bioinform/DATA/rna_seq/Dougherty/pSI.data/data/human.rda")
load("C:/Users/grossar/Bioinform/DATA/rna_seq/Dougherty/pSI.data/data/mouse.rda")
help(pSI)

ensembl = useMart(host='www.ensembl.org',biomart='ENSEMBL_MART_ENSEMBL',dataset="hsapiens_gene_ensembl")
filters = listFilters(ensembl)
attributes = listAttributes(ensembl)

########################################################################
### Functions
########################################################################
convertIDs <- function(dataframe) {
  ensemblIDs <- c()
  for (rowName in row.names(dataframe)) {
    ensemblID <- strsplit(rowName,"\\.")[[1]][1]
    ensemblIDs <- c(ensemblIDs,ensemblID)
  }
  row.names(dataframe)<-ensemblIDs
  return(dataframe)
}

addMedSD <- function(dataframe) {
  median <- apply(dataframe,1,median)
  sd <- apply(dataframe,1,sd)
  return(data.frame(dataframe,median,sd))  
}

sortByMed <- function(dataframe) {
  order <- order(dataframe$median,decreasing=TRUE)
  return(dataframe[order,])
}
addGene <- function(dataframe) {
  genes <- getBM(attributes=c('ensembl_gene_id','external_gene_name'), filters='ensembl_gene_id', values=row.names(dataframe), mart=ensembl)
  genes <- genes[match(row.names(dataframe),genes[,1]),]
  Gene <- c()
  for (rowNumber in 1:length(genes[,1])) {
    newGene <- genes[rowNumber,][,2]
    Gene <- c(Gene, newGene)
  }
  dataframe[length(dataframe)+1] <- Gene
  names(dataframe)[ncol(dataframe)] <- "Gene"
  return(dataframe)
}
generate.gtex.data <- function(ids.of.interest.full,length,output.table) {
  ### Generate list of ids ##########################################
  ids.of.interest <- ids.of.interest.full[1:length] # Subselects based on the specified depth
  ### Calculate p-values ############################################
  gtex.results <- fisher.iteration(pSIs = psi.gtex, candidate.genes = ids.of.interest)
  ### Output data table #############################################
  print(output.table) # Reminds user whether they requested an output table of p-values
  if(output.table == TRUE) {
    print('Outputting table')
    setwd("z://Data/RNAseq HT neurons and tissue/Andrews_files/pSI_files/pSI_results/")
    write.csv(gtex.results, paste0("gtex_",geneset,"_",length,"_",strftime(Sys.time(),"%a%b%d%H%M"),".csv"))
  }
  ### Format gtex data ##############################################
  gtex.plotting <- gtex.results[gtex.results$`0.01 - adjusted` != 1,]
  names(gtex.plotting) <- c('p0.05','p0.01','p0.001','p1e-4')
  gtex.plotting <- gtex.plotting[c('p0.01','p0.001','p1e-4')]
  gtex.plotting <- -log10(gtex.plotting)
  gtex.plotting$tissue <- row.names(gtex.plotting)
  gtex.plotting[order(gtex.plotting$p0.01,decreasing = TRUE),]
  #gtex.plotting.melt <- melt(gtex.plotting,id.var = "tissue")
  return(gtex.plotting)
}

generate.gtex.fig.from.data <- function(gtex.plotting.melt) {
  ### Plot gtex data ################################################
  gtex.plot <- ggplot(data = gtex.plotting.melt,aes(x = reorder(tissue, -value), y = value, fill = variable)) +
    geom_bar(position = "dodge",stat="identity") +
    labs(title = paste("Overlap of the top",length,"genes in",geneset,"and gtex"),
         x = "Tissue",
         y = "Negative log10 p-value") +
    theme(plot.title = element_text(color="black", face="bold", size=22, margin=margin(10,0,20,0)),
          axis.title.x = element_text(face="bold", size=14,margin =margin(20,0,10,0)),
          axis.title.y = element_text(face="bold", size=14,margin =margin(0,20,0,10)),
          plot.margin = unit(c(1,1,1,1), "cm"), axis.text = element_text(size = 12),
          panel.background = element_rect(fill = 'white', colour = 'black'),
          axis.text.x = element_text(angle = 90, hjust = 1)) +
    scale_fill_brewer("p-value",palette = 'Reds')
  ### Display plot ##################################################
  return(gtex.plot)
  ### Save plot #####################################################
  tiff(filename=paste0("gtex_",geneset,"_",length,"_",strftime(Sys.time(),"%a%b%d%H%M"),".tiff"), 
       type="cairo",
       units="in", 
       width=14, 
       height=14, 
       pointsize=12,
       res=100)
  gtex.plot
  dev.off() 
}

generate.tsea.figure <- function(genes.of.interest.full,length,output.table) {
  ### Generate list of ids ##########################################
  genes.of.interest <- genes.of.interest.full[1:length]
  ### Calculate p-values ############################################
  tsea.results <- fisher.iteration(pSIs = psi.tsea, candidate.genes = genes.of.interest)
  ### Output data table #############################################
  print(output.table)
  if(output.table == TRUE) {
    print('Outputting table')
    setwd("z://Data/RNAseq HT neurons and tissue/Andrews_files/pSI_files/pSI_results/")
    write.csv(tsea.results, paste0("tsea_",geneset,"_",length,"_",strftime(Sys.time(),"%a%b%d%H%M"),".csv"))
  }
  ### Format tsea data ##############################################
  tsea.plotting <- tsea.results[tsea.results$`0.01 - adjusted` != 1,]
  names(tsea.plotting) <- c('p0.05','p0.01','p0.001','p1e-4')
  tsea.plotting <- tsea.plotting[c('p0.01','p0.001','p1e-4')]
  tsea.plotting <- -log10(tsea.plotting)
  tsea.plotting$tissue <- row.names(tsea.plotting)
  tsea.plotting[order(tsea.plotting$p0.01,decreasing = TRUE),]
  tsea.plotting.melt <- melt(tsea.plotting,id.var = "tissue")
  ### Plot tsea data ################################################
  tsea.plot <- ggplot(data = tsea.plotting.melt,aes(x = reorder(tissue, -value), y = value, fill = variable)) +
    geom_bar(position = "dodge",stat="identity") +
    labs(title = paste("Overlap of the top",length,"genes in",geneset,"and tsea"),
         x = "Tissue",
         y = "Negative log10 p-value") +
    theme(plot.title = element_text(color="black", face="bold", size=22, margin=margin(10,0,20,0)),
          axis.title.x = element_text(face="bold", size=14,margin =margin(20,0,10,0)),
          axis.title.y = element_text(face="bold", size=14,margin =margin(0,20,0,10)),
          plot.margin = unit(c(1,1,1,1), "cm"), axis.text = element_text(size = 12),
          panel.background = element_rect(fill = 'white', colour = 'black'),
          axis.text.x = element_text(angle = 90, hjust = 1)) +
    scale_fill_brewer("p-value",palette = 'Reds')
  ### Display plot ##################################################
  return(tsea.plot)
}

add.bands.between <- function(dataframe, width) {
  new.df <- dataframe[1,]
  new.df[4] <- new.df[2] - width
  new.df <- rbind(new.df,c(as.character(unlist(dataframe[1,][1])),0,0.1,width))
  for(line in 2:nrow(dataframe)) {
    current.line <- dataframe[line,]
    current.line[4] <- current.line[2]-width
    new.df <- rbind(new.df,current.line)
    new.df <- rbind(new.df,c(as.character(unlist(dataframe[line,][1])),0,0.1,width))
  }
  new.df[2] <- as.numeric(new.df[,2])
  new.df[3] <- as.numeric(new.df[,3])
  new.df[4] <- as.numeric(new.df[,4])
  return(new.df)
}

generate.bullseyes <- function(dataframe, plot.max.lim) {
  plot.list <- list()
  for(sample.pos in seq(1,length(dataframe[,1])/8)){
    gtex.plotting.sub <- gtex.plotting[(((sample.pos-1)*8)+1):(((sample.pos-1)*8)+8),]
    current.plot <- ggplot(data = gtex.plotting.sub, aes(x = Sample, y = Set.size, fill = p.Value)) +
      geom_bar(width = 1, stat = "identity") + 
      scale_y_continuous(limits = c(0,plot.max.lim)) +
      xlab(gtex.plotting.sub[1][1,]) +
      theme(axis.title.x = element_text(face="bold", size=14,margin =margin(0,0,15,0)),
            axis.title.y = element_blank(), axis.ticks = element_blank(), axis.text = element_blank(),
            plot.margin = unit(c(0,0,0,0), "cm"), axis.text = element_text(size = 12),
            panel.background = element_rect(fill = 'white'), legend.position="none") +  
      coord_polar() +
      scale_fill_distiller(palette = 'YlOrRd', direction = 1, limits=c(1, 50), oob = censor, na.value = 'gray98') +
      geom_bar(aes(y = bands), width = 1, stat = 'identity', fill = c(alpha('black',0),'black',alpha("black",0),'black',alpha("black",0),'black',alpha("black",0),'black'))
    plot.list[[length(plot.list)+1]] <- current.plot
  }
  print(paste("List contains",length(plot.list),"plots"))
  return(plot.list)
}
########################################################################
### Data input
########################################################################

# Normalized refseq data in units of TPM
TPMdata <- read.csv("z://Data/RNAseq HT neurons and tissue/Andrews_files/20160317_Sareen_rerun-29299281.tpm.csv", row.names=1)

# Metadata
metadata.sam <- read.csv("z://Data/RNAseq HT neurons and tissue/2nd rerun/samples.csv", row.names=1)

### Gtex references
references <- read.table("c://Users/grossar/Bioinform/DATA/rna_seq/Reference_transcriptomes/GTEx_Analysis_v6_RNA-seq_RNA-SeQCv1.1.8_gene_median_rpkm.gct",sep="\t",header=TRUE,row.names=1)

########################################################################
### Formatting
########################################################################
### Format TPM
TPMdata <- TPMdata[row.names(metadata.sam)]  # Reorder columns to match metadata

### Remove unwanted columns
TPMdata <- TPMdata[-match("Reference",names(TPMdata))]
TPMdata <- TPMdata[-match("iHT_02iOBS",names(TPMdata))]
metadata.sam <- metadata.sam[-match("Reference",row.names(metadata.sam)),]
metadata.sam <- metadata.sam[-match("iHT_02iOBS",row.names(metadata.sam)),]

referenceNames <- c("Adipose, subcutaneous","Adipose, omentum","Adrenal gland","Aorta","Coronary artery",
                    "Tibial artery","Bladder","Amygdala","Anterior cingulate cortex","Caudate nucleous",
                    "Cerebellar hemisphere","Cerebellum","Cortex","Frontal cortex BA9",
                    "Hippocampus","Hypothalamus","Nucleus accumbens","Putamen",
                    "Spinal cord","Substantia nigra","Mammary","Transformed Lymphocyte","Fibroblast","Ectocervix",
                    "Endocervix","Colon, sigmoid","Colon, transverse","Gastroesophageal junction","Esophagus, mucosa",
                    "Esophagus, muscularis","Fallopian tube","Heart, Atrial","Heart, left ventricle",
                    "Kidney","Liver","Lung","Salivary gland","Skeletal muscle","Tibial nerve","Ovary","Pancreas",
                    "Pituitary","Prostate","Skin, sun-hidden","Skin, sun-exposed","Small intestine","Spleen","Stomach","Testis","Thyroid","Uterus","Vagina","Whole blood")

########################################################################
### Subsetting -- Generate metadata tables and expression tables that only include certain samples based on critieria such as cell type
########################################################################

### Subset metadata files -- Metadata files contain data used for subsetting expression data sets and, later, formatting plots
metadata.sam.HT <- na.omit(metadata.sam[metadata.sam$Type == "HT",])       # all HT samples (iPSC + adult)
metadata.sam.iHT <- metadata.sam[metadata.sam$Group == 'iHT',]             # iPSC HT samples
metadata.sam.iHT.C <- metadata.sam.iHT[metadata.sam.iHT$Disease == 'CTR',] # iPSC HT control samples
metadata.sam.aHT <- metadata.sam[metadata.sam$Source == "Adult",]          # Adult HT samples
metadata.sam.iPSC <- metadata.sam[metadata.sam$Source == "iPSC",]          # all iPSC samples (iHT + iMN)
metadata.sam.MN <- na.omit(metadata.sam[metadata.sam$Type == "MN",])       # Motor neuron samples
metadata.sam.HT.f <- metadata.sam.HT[metadata.sam.HT$Sex =='F',]           # female HT samples
metadata.sam.iHT.f <- metadata.sam.iHT[metadata.sam.iHT$Sex =='F',]        # female iHT samples

### Subset expression data
HT.data <- TPMdata[match(row.names(metadata.sam.HT),names(TPMdata))]       # All hypothalamus samples (iPSC + adult)
iHT.data <- TPMdata[match(row.names(metadata.sam.iHT),names(TPMdata))]     # iPSC hypothalamus samples
iHT.C.data <- TPMdata[match(row.names(metadata.sam.iHT.C),names(TPMdata))] # iPSC hypothalamus control samples
aHT.data <- TPMdata[match(row.names(metadata.sam.aHT),names(TPMdata))]     # Adult hypothalamus samples
iPSC.data <- TPMdata[match(row.names(metadata.sam.iPSC),names(TPMdata))]   # all iPSC samples (iHT + iMN)
MN.data <- TPMdata[match(row.names(metadata.sam.MN),names(TPMdata))]       # Motor Neuron samples
iHT.f.data <- TPMdata[match(row.names(metadata.sam.iHT.f),names(TPMdata))] # female HT samples
HT.f.data <- TPMdata[match(row.names(metadata.sam.HT.f),names(TPMdata))]   # female iHT samples

### Reference expression data -- Generate tables of expression data for certain samples in the GTEx dataset
GTEx.HT <- convertIDs(references['Brain...Hypothalamus'])

### Join all data sets into a list from which to select
datalist <- list(HT.data,iHT.data,iHT.C.data,aHT.data,iPSC.data,MN.data,iHT.f.data,HT.f.data,GTEx.HT)
names(datalist) <- c("HT","iHT","iHT.ctr","aHT","iPSC","MN","iHT.f","HT.f","GTEx.HT")

########################################################################
### Reorder genes by expression -- generate lists of genes ranked from most expressed to least for each data set.  These lists can be subset at any length to give the top n number of genes.
########################################################################
### Add Median and sort by median
for(list.element in 1:length(datalist)) {
  datalist[[list.element]] <- sortByMed(addMedSD(datalist[[list.element]]))[1:4000,]
}
### Generate full lists of genes
genelist <- datalist
for(list.element in 1:length(datalist)) {
  current.genelist <- addGene(genelist[[list.element]])
  genelist[[list.element]] <- current.genelist[ncol(current.genelist)]
}

########################################################################
### Select gene list - Format the gene lists and select the one with which to proceed.
########################################################################

names(genelist)  # Lists the available data sets in the list of datasets
geneset <- 4  # Specifies the data set to use
genes.of.interest.full <- genelist[[geneset]][,1] # Declares the genes to use
ids.of.interest.full <- row.names(genelist[[geneset]]) # Declares the IDs of the genes to use
geneset <- names(genelist[geneset]) # Names the geneset for use in plot titles
print(geneset) # Reports the geneset in use

########################################################################
### Output gene lists for web app -- Outputs the top n number of genes in the selected data set in a file that can be pasted into the Dougherty web app
########################################################################

length <- 2000

gene.abrv.df <- getBM(attributes=c('ensembl_gene_id','external_gene_name','hgnc_symbol'), filters='ensembl_gene_id', values=ids.of.interest.full[1:length], mart=ensembl)
gene.abrv.df <- gene.abrv.df[match(ids.of.interest.full[1:length],gene.abrv.df[,1]),]
gene.abrv.list <- gene.abrv.df[,2]
#setwd("z://Data/RNAseq HT neurons and tissue/Andrews_files/pSI_files/pSI_results/")
write(gene.abrv.list, paste0("z://Data/RNAseq HT neurons and tissue/Andrews_files/pSI_files/gene lists/",geneset,"-",length,"_",strftime(Sys.time(),"%a%b%d%H%M"),".txt")); print(paste('Wrote',paste0("gene_list-",geneset,"-",length,"_",strftime(Sys.time(),"%a%b%d%H%M"),".txt")))
#write(human.genes, paste0("z://Data/RNAseq HT neurons and tissue/Andrews_files/pSI_files/gene lists/",geneset,"-",length,"_",strftime(Sys.time(),"%a%b%d%H%M"),".csv")); print(paste('Wrote',paste0("gene_list-",geneset,"-",length,"_",strftime(Sys.time(),"%a%b%d%H%M"),".txt")))

########################################################################
### pSI determination -- Generate the pSI values for each gene within each sample.  This process can be slow, so it should only need to be done once for specific lists of samples, then saved and reused.
########################################################################

### Declare the input data set
#pSI.input <- sample.data$pSI.input  # Use the sample data as input
#pSI.input <- references[2:ncol(references)]  # Use the full GTEx data set as input
pSI.input <- references[-c(1,24)]      # Use the GTEx data set, minus fibroblast.
#pSI.input <- references[-c(1,24,45,46)]      # Use the GTEx data set, minus skin or fibroblast entries.
#pSI.input <- references[c(4,9,10,11,12,13,14,15,16,17,18,19,20,21,40,43)]      # Use the samples in the GTEx dataset which come from the brain
pSI.input <- convertIDs(pSI.input)  #  Convert ids to remove the decimal in the ENSMBL ids

### Calculate the pSI table and the gene count from the pSI table
pSI.output <- specificity.index(pSI.input)  # The specificity.index() generates a table of pSI values
pSI.thresholds <- pSI.list(pSI.output)      #
psi.counts <- pSI.count(pSI.output)         # Generate a counts table, containing the number of gene binned in each pSI level of each sample

########################################################################
### Save pSI tables -- Save the pSI table and the counts table for the specific data set for later reuse.
########################################################################

### Write the pSI and counts files.  
write.csv(pSI.output,"z:/Data/RNAseq HT neurons and tissue/Andrews_files/pSI_files/specificity.indexes/psi_gtex_no-fib_SPEC-INDEX_2016-12-20.csv")
write.csv(psi.counts,"z:/Data/RNAseq HT neurons and tissue/Andrews_files/pSI_files/specificity.indexes/psi_gtex_no-fib_COUNTS_2016-12-20.csv")

########################################################################
### Load pSI tables -- Load previously calculated pSI tables to compare against
########################################################################

### Dougherty tissue list, NAR 2015, Table S3 -- 25 tissues, 18056 genes labeled with gene names
psi.tsea<-read.table("http://genetics.wustl.edu/jdlab/files/2015/10/TableS3_NAR_Dougherty_Tissue_gene_pSI_v3.txt",header=T,row.names=1)

### Dougherty cell types, JoN 2016 -- 60 cell types, 16,866 genes in gene name format
psi.csea <- human$developmental.periods$psi.out

### Gtex, full -- 53 tissues, 56,418 genes labeled with ENSB IDs
psi.gtex <- read.csv("z:/Data/RNAseq HT neurons and tissue/Andrews_files/pSI_files/specificity.indexes/pSI_gTEX_full_10-31-16.csv", header=T,row.names=1)
names(psi.gtex) <- referenceNames

### Gtex, w/o skin -- 50 tissues, 56,418 genes labeled with ENSB IDs
psi.gtex <- read.csv("z:/Data/RNAseq HT neurons and tissue/Andrews_files/pSI_files/specificity.indexes/pSI_GTEx_no-skin_SPEC-INDEX_11-14-16.csv", header=T,row.names=1)
psi.counts <- read.csv("z:/Data/RNAseq HT neurons and tissue/Andrews_files/pSI_files/specificity.indexes/pSI_GTEx_no-skin_COUNTS_11-14-16.csv", header=T,row.names=1)
names(psi.gtex) <- referenceNames[-c(23,44,45)]

### Gtex, brain -- 16 tissues, 56,418 genes labeled with ENSB IDs
psi.gtex <- read.csv("z:/Data/RNAseq HT neurons and tissue/Andrews_files/pSI_files/specificity.indexes/pSI_GTEx_brain_SPEC-INDEX_11-14-16.csv", header=T,row.names=1)
psi.counts <- read.csv("z:/Data/RNAseq HT neurons and tissue/Andrews_files/pSI_files/specificity.indexes/pSI_GTEx_brain_COUNTS_11-11-16.csv", header=T,row.names=1)
names(psi.gtex) <- referenceNames[c(4,9,10,11,12,13,14,15,16,17,18,19,20,21,40,43)]

### Gtex, w/o fib -- 52 tissues, 56,418 genes labeled with ENSB IDs
psi.gtex <- read.csv("z:/Data/RNAseq HT neurons and tissue/Andrews_files/pSI_files/specificity.indexes/psi_gtex_no-fib_SPEC-INDEX_2016-12-20.csv", header=T,row.names=1)
psi.counts <- read.csv("z:/Data/RNAseq HT neurons and tissue/Andrews_files/pSI_files/specificity.indexes/psi_gtex_no-fib_COUNTS_2016-12-20.csv", header=T,row.names=1)
names(psi.gtex) <- referenceNames[-c(23)]

########################################################################
### Generate gtex plot data
########################################################################

length <- 500

ids.of.interest <- ids.of.interest.full[1:length] # Subselects based on the specified depth

### Calculate p-values -- Generate a table of pvalues associated with each tissue at each of the four pSI thresholds
gtex.results <- fisher.iteration(pSIs = psi.gtex, candidate.genes = ids.of.interest)  ### WARNING:  This command can take >4 minutes

### Format gtex data 
names(gtex.results) <- c('p0.05','p0.01','p0.001','p1e-4')  # Rename the columns in the result table
#absent.samples <- row.names(gtex.results[gtex.results$`0.05 - adjusted` == 1,])

########################################################################
########################################################################
### Export/Import p-value table -- After calculating the p values used to generate the hexagon plot, save the table
########################################################################
########################################################################

### Export pSI tables
setwd("z://Data/RNAseq HT neurons and tissue/Andrews_files/pSI_files/pSI_results/")
write.csv(gtex.results, paste0("gtex-ns_",geneset,"_",length,"_",strftime(Sys.time(),"%a%b%d%H%M"),".csv")); print(paste('Wrote',paste0("gtex_",geneset,"_",length,"_",strftime(Sys.time(),"%a%b%d%H%M"))))

### Inport pSI tables
#setwd("z://Data/RNAseq HT neurons and tissue/Andrews_files/pSI_files/pSI_results/")
#input.file <- 'gtex_aHT_1000_TueSep061740.csv'
#input.file <- 'gtex_iHT_1200_WedOct051355.csv'
#gtex.results <- read.csv(input.file,row.names = 1)
gtex.results <- read.csv("z:/Data/RNAseq HT neurons and tissue/Andrews_files/pSI_files/pSI_results/gtex-ns_iHT_250_FriDec091648.csv" ,row.names = 1)
#gtex.counts <- read.csv("z:/Data/RNAseq HT neurons and tissue/Andrews_files/pSI_files/specificity.indexes/pSI_GTEx_no-skin_COUNTS_11-11-16.csv", row.names = 1)

########################################################################
### Rename rows - Row names often get distorted when saving into or out of Excel
########################################################################

### For GTEx, full
#row.names(gtex.results) <- referenceNames
#names(psi.counts) <- referenceNames

### For GTEx, w/o skin
#row.names(gtex.results) <- referenceNames[-c(23,44,45)]
#names(psi.counts) <- referenceNames[-c(23,44,45)]

### For GTEx, brain
#row.names(gtex.results) <- referenceNames[c(4,9,10,11,12,13,14,15,16,17,18,19,20,21,40,43)]
#names(psi.counts) <- referenceNames[c(4,9,10,11,12,13,14,15,16,17,18,19,20,21,40,43)]

### For GTEx, w/o fib
row.names(gtex.results) <- referenceNames[-c(23)]
names(psi.counts) <- referenceNames[-c(23)]

### For all GTEx results, rename the columns
names(gtex.results) <- c('p0.05','p0.01','p0.001','p1e-4')

########################################################################
### Format results for Cytoscape
########################################################################

### Generate a new table to modify
gtex.results.prep <- gtex.results

### Alphabetically sort
gtex.results.prep <- gtex.results.prep[order(row.names(gtex.results.prep)),]

### Reshape the dataframe
pSI.levels <- names(gtex.results) # Copy levels for latel assignment
names(gtex.results.prep) <- rep('p-val',4)  # rename all columns as 'p-val' for easy reshaping
results.for.cytoscape <- rbind(gtex.results.prep[4],gtex.results.prep[3],gtex.results.prep[2],gtex.results.prep[1])
#row.names(results.for.cytoscape) <- c(row.names(gtex.results.prep),seq(1,150))

### Add label columns
sample.label <- rep(row.names(gtex.results.prep),4)
pSI.labels <- c(rep(pSI.levels[4],nrow(gtex.results)),rep(pSI.levels[3],nrow(gtex.results)),rep(pSI.levels[2],nrow(gtex.results)),rep(pSI.levels[1],nrow(gtex.results)))
results.for.cytoscape <- cbind(results.for.cytoscape, sample.label, pSI.labels)

### Log transform the data
results.for.cytoscape[1] <- -log10(results.for.cytoscape[1])

### Confirm output data set name
input.file <- paste0("gtex-nf_",geneset,"_",length)
#input.file <- 'gtex-ns_iht_250'
print(input.file)

### Output
write.csv(results.for.cytoscape,paste0("z:/Data/RNAseq HT neurons and tissue/Andrews_files/pSI_files/output for cytoscape/",input.file,strftime(Sys.time(),"%a%b%d%H%M"),".csv")); print(paste0("z://Data/RNAseq HT neurons and tissue/Andrews_files/pSI_files/output for cytoscape/",input.file,strftime(Sys.time(),"%a%b%d%H%M"),".txt"))



########################################################################
### Format counts and results for plotting in R
########################################################################

### Remove empty rows
#gtex.results.trim <- gtex.results
gtex.results.trim <- gtex.results[gtex.results$p0.05 < 0.1,]
gtex.counts.trim <- gtex.counts[row.names(gtex.results.trim),]
gtex.counts.trim$p1e.4 <- gtex.counts.trim$p1e.4+1

### Reverse row order
gtex.counts.trim <- gtex.counts.trim[c(4,3,2,1)]
gtex.results.trim <- gtex.results.trim[c(4,3,2,1)]

### Melt and join
gtex.plotting <- melt(t(gtex.counts.trim))
gtex.plotting[4] <- melt(t(gtex.results.trim))[3]
gtex.plotting[5] <- gtex.plotting[3]
gtex.plotting <- gtex.plotting[c(2,3,4,5)]
names(gtex.plotting) <- c('Sample', 'Set.size', 'p.Value', 'bands')

### Rescale and rename
gtex.plotting[2] <- log10(gtex.plotting[2]+1)
gtex.plotting[3] <- -log10(gtex.plotting[3])
#gtex.plotting[4] <- log10(gtex.plotting[4]+1)

### Add bands between bands
gtex.plotting <- add.bands.between(gtex.plotting,0.25)

### Calculate maximum bullseye size for plot limits
plot.max.lim <- ceiling(max(rowSums(log10(gtex.counts.trim))))

########################################################################
### Plot one bullseye
########################################################################

### Declare the gene of interest by giving its position
sample.pos <- 5

### Declare a subsetted dataframe using the specified gene of interest's position
gtex.plotting.sub <- gtex.plotting[(((sample.pos-1)*8)+1):(((sample.pos-1)*8)+8),]

### Generate plot
ggplot(data = gtex.plotting.sub, aes(x = Sample, y = Set.size, fill = p.Value)) +
  geom_bar(width = 1, stat = "identity") + 
  scale_y_continuous(limits = c(0,12)) +
  xlab(gtex.plotting.sub[1][1,]) +
  theme(axis.title.x = element_text(face="bold", size=14,margin =margin(0,0,10,0)),
        axis.title.y = element_blank(), axis.ticks = element_blank(), axis.text = element_blank(),
        plot.margin = unit(c(0,0,0,0), "cm"), axis.text = element_text(size = 12),
        panel.background = element_rect(fill = 'white')) +  coord_polar() +
  scale_fill_distiller(palette = 'YlOrRd', direction = 1, limits=c(1, 50), oob = censor, na.value = 'gray95') +
  geom_bar(aes(y = bands), width = 1, stat = 'identity', fill = c(alpha('black',0),'black',alpha("black",0),'black',alpha("black",0),'black',alpha("black",0),'black'))
  
########################################################################
### Plot tissue types in batch for faceting
########################################################################

plot.list <- generate.bullseyes(gtex.plotting, plot.max.lim)

########################################################################
### Generate faceted plots
########################################################################
print(paste('There are', length(plot.list), 'tissue types available for plotting'))

### Specify bullseyes to plot
p.l <- plot.list

n <- length(p.l); nCol <- floor(sqrt(n))

(tiled.figure <- do.call("grid.arrange", c(p.l, ncol=nCol)))




(tiled.figure <- grid.arrange(plot.list[[1]],plot.list[[2]],plot.list[[3]],plot.list[[4]],
                              ncol = 4, top = title))


##########################################################
### Saving faceted plots
##########################################################

title.split <- strsplit(gtex.plot$labels$title," ")[[12]]
geneset <- title.split[8]
length <- title.split[5]

getwd()
png(filename=paste0("gtex_",geneset,"_",length,"_",strftime(Sys.time(),"%a%b%d%H%M"),".png"), 
     type="cairo",
     units="in", 
     width=14, 
     height=14, 
     pointsize=12,
     res=300)
do.call("grid.arrange", c(p.l, ncol=nCol))
dev.off()



### Save plot
tiff(filename=paste0("gtex_",geneset,"_",length,"_",strftime(Sys.time(),"%a%b%d%H%M"),".tiff"), 
     type="cairo",
     units="in", 
     width=14, 
     height=14, 
     pointsize=12,
     res=100)
gtex.plot
dev.off()

### Generate multiple plots in list
start <- 600
end <- 2600
step <- 200

gtex.plots <- list()
for(length in seq(start,end,step)) {
  print(paste("Generating",length(seq(start,end,step)),"plots using",geneset))
  gtex.plots[[length(gtex.plots)+1]] <- generate.gtex.figure(ids.of.interest.full,length = length,FALSE)
  print(paste('plot of',length,'genes complete'))
}

### View plots in list
gtex.plot <- gtex.plots[[8]]
gtex.plot



########################################################################
### Generate tsea data and figures
########################################################################

length = 2222

### Generate the plot
tsea.plot <- generate.tsea.figure(genes.of.interest.full,length,FALSE)

### Generate the gene list from brain
tsea.brain.genes <- 

### Display the plot
tsea.plot

### Save plot
tiff(filename=paste0("tsea_",geneset,"_",length,"_",strftime(Sys.time(),"%a%b%d%H%M"),".tiff"), 
     type="cairo",
     units="in", 
     width=14, 
     height=14, 
     pointsize=12,
     res=100)
tsea.plot
dev.off()

### Define an empty list
brain.genes <- list()

### Generate lists of overlapping genes for the given gene depth
tsea.genes <- candidate.overlap(pSIs = psi.tsea, candidate.genes = genes.of.interest.full[1:length])

### Add brain genes to list
brain.genes[[length(brain.genes)+1]] <- tsea.genes$pSi_0.05$Brain_0.05 ; names(brain.genes)[length(brain.genes)] <- paste0("brain_0.05-",length)
brain.genes[[length(brain.genes)+1]] <- tsea.genes$pSi_0.01$Brain_0.01 ; names(brain.genes)[length(brain.genes)] <- paste0("brain_0.01-",length)
brain.genes[[length(brain.genes)+1]] <- tsea.genes$pSi_0.001$Brain_0.001 ; names(brain.genes)[length(brain.genes)] <- paste0("brain_0.001-",length)



########################################################################
### Calculate overlap p-values
########################################################################

tsea.results <- fisher.iteration(pSIs = psi.tsea, candidate.genes = genes.of.interest)
csea.results <- fisher.iteration(pSIs = psi.csea, candidate.genes = genes.of.interest)
gtex.results <- fisher.iteration(pSIs = psi.gtex, candidate.genes = ids.of.interest)

########################################################################
### Report significant genes
########################################################################

tsea.genes <- candidate.overlap(pSIs = psi.tsea, candidate.genes = genes.of.interest)

brain.genes <- list()

brain.genes[[length(brain.genes)+1]] <- tsea.genes$pSi_0.05$Brain_0.05
brain.genes[[length(brain.genes)+1]] <- tsea.genes$pSi_0.01$Brain_0.01
brain.genes[[length(brain.genes)+1]] <- tsea.genes$pSi_0.001$Brain_0.001


########################################################################
### Save p-value results
########################################################################

timestamp <- strftime(Sys.time(),"%a%b%d%H%M")
setwd("z://Data/RNAseq HT neurons and tissue/Andrews_files/pSI_files/pSI_results/")

write.csv(tsea.results, paste0("tsea_",geneset,"_",length,"_",timestamp,".csv"))
write.csv(csea.results, paste0("csea_",geneset,"_",length,"_",timestamp,".csv"))
write.csv(gtex.results, paste0("gtex_",geneset,"_",length,"_",timestamp,".csv"))

########################################################################
### Load p-value results
########################################################################

#setwd("z://Data/RNAseq HT neurons and tissue/Andrews_files/pSI_files/pSI_results/")

#tsea.results <- read.csv("tsea_")
#csea.results <- read.csv("csea_")
#gtex.results <- read.csv("gtex_")

########################################################################
### Visualize results
########################################################################
### Plot bar graphs 

### Format TSEA data
tsea.plotting <- tsea.results[tsea.results$`0.05 - adjusted` != 1,]
names(tsea.plotting) <- c('p0.05','p0.01','p0.001','p1e-4')
tsea.plotting <- -log10(tsea.plotting)
tsea.plotting$tissue <- row.names(tsea.plotting)
tsea.plotting.melt <- melt(tsea.plotting,id.var = "tissue")

### Plot TSEA data
tsea.plot <- ggplot(data = tsea.plotting.melt,aes(x = reorder(tissue, -value), y = value, fill = variable)) +
  geom_bar(position = "dodge",stat="identity") + 
  labs(title = paste("p-value of the overlap of the top",length,"genes in",geneset),
       x = "Tissue",
       y = "Negative log10 p-value") +
  theme(plot.title = element_text(color="black", face="bold", size=22, margin=margin(10,0,20,0)),
        axis.title.x = element_text(face="bold", size=14,margin =margin(20,0,10,0)),
        axis.title.y = element_text(face="bold", size=14,margin =margin(0,20,0,10)),
        plot.margin = unit(c(1,1,1,1), "cm"), axis.text = element_text(size = 12),
        panel.background = element_rect(fill = 'white', colour = 'black'),
        axis.text.x = element_text(angle = 90, hjust = 1)) +
  scale_fill_brewer("p-value",palette = 'OrRd', direction = -1)

tsea.plot

### Format CSEA data
csea.plotting <- csea.results[csea.results$`0.05 - adjusted` != 1,]
names(csea.plotting) <- c('p0.05','p0.01','p0.001','p1e-4')
csea.plotting <- -log10(csea.plotting)
csea.plotting$tissue <- row.names(csea.plotting)
csea.plotting.melt <- melt(csea.plotting,id.var = "tissue")

### Plot CSEA data
csea.plot <- ggplot(data = csea.plotting.melt,aes(x = reorder(tissue, -value), y = value, fill = variable)) +
  geom_bar(position = "dodge",stat="identity") + 
  labs(title = paste("p-value of the overlap of the top",length,"genes in",geneset),
       x = "Tissue",
       y = "Negative log10 p-value") +
  theme(plot.title = element_text(color="black", face="bold", size=22, margin=margin(10,0,20,0)),
        axis.title.x = element_text(face="bold", size=14,margin =margin(20,0,10,0)),
        axis.title.y = element_text(face="bold", size=14,margin =margin(0,20,0,10)),
        plot.margin = unit(c(1,1,1,1), "cm"), axis.text = element_text(size = 12),
        panel.background = element_rect(fill = 'white', colour = 'black'),
        axis.text.x = element_text(angle = 90, hjust = 1)) +
  scale_fill_brewer("p-value",palette = 'OrRd', direction = -1)

csea.plot

### Format gtex data
gtex.plotting <- gtex.results[gtex.results$`0.01 - adjusted` != 1,]
names(gtex.plotting) <- c('p0.05','p0.01','p0.001','p1e-4')
gtex.plotting <- gtex.plotting[c('p0.01','p0.001','p1e-4')]
gtex.plotting <- -log10(gtex.plotting)
gtex.plotting$tissue <- row.names(gtex.plotting)
gtex.plotting[order(gtex.plotting$p0.05,decreasing = TRUE),]
gtex.plotting.melt <- melt(gtex.plotting,id.var = "tissue")

### Plot gtex data
gtex.plot <- ggplot(data = gtex.plotting.melt,aes(x = reorder(tissue, -value), y = value, fill = variable)) +
  geom_bar(position = "dodge",stat="identity") + 
  labs(title = paste("Overlap of the top",length,"genes in",geneset,"and gtex"),
       x = "Tissue",
       y = "Negative log10 p-value") +
  theme(plot.title = element_text(color="black", face="bold", size=22, margin=margin(10,0,20,0)),
        axis.title.x = element_text(face="bold", size=14,margin =margin(20,0,10,0)),
        axis.title.y = element_text(face="bold", size=14,margin =margin(0,20,0,10)),
        plot.margin = unit(c(1,1,1,1), "cm"), axis.text = element_text(size = 12),
        panel.background = element_rect(fill = 'white', colour = 'black'),
        axis.text.x = element_text(angle = 90, hjust = 1)) +
  scale_fill_brewer("p-value",palette = 'Reds')

gtex.plot

########################################################################
### Output plots
########################################################################

setwd("z://Data/RNAseq HT neurons and tissue/Andrews_files/pSI_files/pSI_results/")

tiff(filename=paste0("tsea_",geneset,"_",length,"_",strftime(Sys.time(),"%a%b%d%H%M"),".tiff"), 
     type="cairo",
     units="in", 
     width=14, 
     height=14, 
     pointsize=12, 
     res=100)
tsea.plot
dev.off()

tiff(filename=paste0("csea_",geneset,"_",length,"_",strftime(Sys.time(),"%a%b%d%H%M"),".tiff"), 
     type="cairo",
     units="in", 
     width=14, 
     height=14, 
     pointsize=12, 
     res=100)
csea.plot
dev.off()


########################################################################
### Scratch work
########################################################################


(tiled.figure<-grid.arrange(p.l[[1]],p.l[[2]],p.l[[3]],p.l[[4]],p.l[[5]],
                            p.l[[6]],p.l[[7]],p.l[[8]],p.l[[9]],p.l[[10]],
                            p.l[[11]],p.l[[12]],p.l[[13]],p.l[[14]],p.l[[15]],
                            ncol = 5, top = title))
