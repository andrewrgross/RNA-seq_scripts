######################################################################################
###### Proteomic analysis for networks, 2016-02-17
######################################################################################
### Functions

convert.char.column.to.num <- function(dataframe,column) {
  new.vector <- c()
  for (value in dataframe[,column]) {
    new.value <- as.numeric(strsplit(as.character(value),"/")[[1]][1])
    new.vector <- c(new.vector,new.value)
  }
  dataframe[column] <- new.vector
  return(dataframe)
}
######################################################################################
### Upload data

setwd(dir = "Z:/Uthra/HT paper/Bioinformatics figures/IPA analysis/network_files_for_cytoscape/")
networks <- read.csv("z:/Data/C9-ALS MNs and bioenergetics/Mass Spec/Dhruv Sareen/Report 2015.02/Andrew/IPA_pathways_3.csv")
gene.fc <- read.csv('Z:/Data/C9-ALS MNs and bioenergetics/Mass Spec/Dhruv Sareen/Report 2015.02/Andrew/Gene_fold_changes.csv')    # Import genes and their fold changes

networks <- networks[-4]
length <- nrow(networks)

######################################################################################
### Format new columns

for(column in 4:7){
  networks <- convert.char.column.to.num(networks,column)
}

######################################################################################
### Calculate shared genes

outputNetwork <- data.frame(sources=character(),target=character(),
                     interaction=character(),boolean=character(),
                     string=character(),shared=double(),
                     stringsAsFactors=FALSE)

for (i in 1:(length-1)) {                                           # Run through each node in turn
  sourceName <- toString(networks$Ingenuity.Canonical.Pathways[i])        # Define current source
  molecules <- networks$Molecules[i]                            # Generate a string of molecules in the current node
  moleculesA <- unlist(strsplit(toString(molecules),","))       # Convert string to list
  for (j in 1:(length-i)) {                                     # Run through each of the nodes following the current one
    targetName <- toString(networks$Ingenuity.Canonical.Pathways[i+j])      # Define current source
    molecules <- networks$Molecules[i+j]                        # Generate a string of molecules
    moleculesB <- unlist(strsplit(toString(molecules),","))     # Convert string to list
    count <- length(intersect(moleculesA,moleculesB))           # Calculate the number of genes shared between the nodes
    row <- c(sourceName,targetName,"cooccurrence","TRUE","ABC",count)
    outputNetwork[length(outputNetwork[,1])+1,] <- row
  }
}

outputNode <- networks[1:7]
names(outputNode) <- c("sources","pVal","ratio","Downregulated","No.change","Upregulated","No.overlap")

######################################################################################
### Format alternate gene plot

### Generate an empty data frame for holding a list of genes and groups
output.gene.node <- data.frame(sources = character(), label = character(), group = character(), size = double(), fc = double(), type = character(), stringsAsFactors=FALSE)
output.gene.net <- data.frame(sources=character(),target=character(),interaction=character(),boolean=character(), string=character(),shared=character(), stringsAsFactors=FALSE)

full.gene.list <- c('GENES!')

### Loop through the pathways and add genes
for(pathway.num in 1:length) {
  genes <- as.character(networks$Molecules[pathway.num])
  genes <- strsplit(genes,',')[[1]]
  pathway = as.character(networks$Ingenuity.Canonical.Pathways[pathway.num])
  total.genes <- sum(networks[pathway.num,][4:7])
  output.gene.node <- rbind(output.gene.node,data.frame(sources = as.character(pathway), label = as.character(pathway), group=as.character("PATHWAY"), size = total.genes, fc = 0, type = 'pathway'))
  output.gene.net <- rbind(output.gene.net, data.frame(sources = as.character(pathway), target = as.character(''), interaction = 'cooccurrence',boolean = "TRUE",string = "ABC", shared = "0"))
  for (gene in genes) {                                      # Loop through all genes in a pathway
    gene.row <- grep(gene,gene.fc$Symbol)
    fold.change <- gene.fc$Expr.Log.Ratio[gene.row]
    gene.type <- as.character(gene.fc$Type.s.[gene.row])
    source.name <- gene
    target <- ''
    count <- "0"
    if(TRUE %in% grepl(source.name,full.gene.list) == TRUE){
      target <- source.name
      source.name <- paste0(source.name,'_i')
      count <- "1"
      }
    output.gene.node <- rbind(output.gene.node,data.frame(sources = as.character(source.name), label= as.character(gene), group=as.character(pathway), size = 1, fc = fold.change, type = gene.type))
    output.gene.net <- rbind(output.gene.net, data.frame(sources = as.character(source.name), target = as.character(target), interaction = 'cooccurrence', boolean = "TRUE",string ="ABC",shared = count))
    #print(data.frame(sources = as.character(source.name, target = as.character(target))))
    full.gene.list <- c(full.gene.list,source.name)
  }
}

######################################################################################
### Output shared genes

setwd(dir = "Z:/Data/C9-ALS MNs and bioenergetics/Mass Spec/Dhruv Sareen/Report 2015.02/Andrew/network files for cytoscape/")
names(outputNetwork) <- c("source","target","interaction","boolean attribute","string attribute","floating point attribute")
write.table(outputNetwork,paste0("NET--C9-pathways-for_cytoscape_",substr(weekdays(Sys.Date()),1,4),"-",format(Sys.Date(),"%b-%d"),".txt"),row.names=FALSE,sep="\t",quote=FALSE)
write.table(outputNode,paste0("NODE--C9-pathways_for_cytoscape_",substr(weekdays(Sys.Date()),1,4),"-",format(Sys.Date(),"%b-%d"),".txt"),row.names=FALSE,sep="\t",quote=FALSE)

### Output alternate plot files
write.table(output.gene.node, paste0("GENE-NODES--C9-pathways_for_cytoscape_",substr(weekdays(Sys.Date()),1,4),"-",format(Sys.Date(),"%b-%d"),".txt"),row.names=FALSE,sep="\t",quote=FALSE)
write.table(output.gene.net, paste0("GENE-NET--C9-pathways_for_cytoscape_",substr(weekdays(Sys.Date()),1,4),"-",format(Sys.Date(),"%b-%d"),".txt"),row.names=FALSE,sep="\t",quote=FALSE)
