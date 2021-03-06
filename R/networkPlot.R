#' Plotting Bibliographic networks
#'
#' \code{networkPlot} plots a bibliographic network.
#'
#' The function \code{\link{networkPlot}} can plot a bibliographic network previously created by \code{\link{biblioNetwork}}.
#' The network map can be plotted using internal R routines or using \href{http://www.vosviewer.com/}{VOSviewer} by Nees Jan van Eck and Ludo Waltman.
#' @param NetMatrix is a network matrix obtained by the function \code{\link{biblioNetwork}}. 
#' @param n is an integer. It indicates the number of vertices to plot.
#' @param type is a character object. It indicates the network map layout:
#' 
#' \tabular{lll}{
#' \code{type="circle"}\tab   \tab Circle layout\cr
#' \code{type="sphere"}\tab   \tab Sphere layout\cr
#' \code{type="mds"}\tab   \tab Multidimensional Scaling layout\cr
#' \code{type="fruchterman"}\tab   \tab Fruchterman-Reingold layout\cr
#' \code{type="kamada"}\tab   \tab  Kamada-Kawai layout\cr
#' \code{type="vosviewer"}\tab   \tab Network is plotted using VOSviewer software\cr}
#' 
#' @param Title is a character indicating the plot title. 
#' @param vos.path is a character indicating the full path whre VOSviewer.jar is located.
#' @param size is logical. If TRUE the point size of each vertex is proportional to its degree. 
#' @param noloops is logical. If TRUE loops in the network are deleted.
#' @param remove.isolates is logical. If TRUE isolates vertices are not plotted.
#' @param remove.multiple is logical. If TRUE multiple links are plotted using just one edge.
#' @param labelsize is an integer. It indicates the label size in the plot. Default is \code{labelsize=1}
#' @param halo is logical. If TRUE communities are plotted using different colors. Default is \code{halo=FALSE}
#' @param cluster is a character. It indicates the type of cluster to perform among ("null", optimal", "lovain","infomap","edge_betweenness","walktrap").
#' @param curved is a logical. If TRUE edges are plotted with an optimal curvature. Default is \code{curved=FALSE}
#' @param weighted This argument specifies whether to create a weighted graph from an adjacency matrix. 
#' If it is NULL then an unweighted graph is created and the elements of the adjacency matrix gives the number of edges between the vertices. 
#' If it is a character constant then for every non-zero matrix entry an edge is created and the value of the entry is added as an edge attribute 
#' named by the weighted argument. If it is TRUE then a weighted graph is created and the name of the edge attribute will be weight.
#' @param edgesize is an integer. It indicates the network edge size.
#' @return It is a network object of the class \code{igraph}.
#' 
#' @examples
#' # EXAMPLE Co-citation network
#'
#' data(scientometrics)
#'
#' NetMatrix <- biblioNetwork(scientometrics, analysis = "co-citation", 
#' network = "references", sep = ";")
#' 
#' net <- networkPlot(NetMatrix, n = 20, type = "kamada", Title = "Co-Citation")
#' 
#' @seealso \code{\link{biblioNetwork}} to compute a bibliographic network.
#' @seealso \code{\link{cocMatrix}} to compute a co-occurrence matrix.
#' @seealso \code{\link{biblioAnalysis}} to perform a bibliometric analysis.
#' 
#' @export
networkPlot<-function(NetMatrix, n=20,Title="Plot", type="kamada", labelsize=1, halo=FALSE, cluster="walktrap", vos.path=NULL, size=FALSE, curved=FALSE, noloops=TRUE, remove.multiple=TRUE,remove.isolates=FALSE,weighted=NULL,edgesize=1){

NET=NetMatrix

# Create igraph object
bsk.network <- graph.adjacency(NET,mode="undirected",weighted=weighted)
V(bsk.network)$id <- colnames(NET)

# Compute node degrees (#links) and use that to set node size:
deg <- degree(bsk.network, mode="all")
if (isTRUE(size)){V(bsk.network)$size <- (deg/max(deg)[1])*20}
else{V(bsk.network)$size=rep(5,length(V(bsk.network)))}

# Select number of vertices to plot
if (n>dim(NET)[1]) {n <- dim(NET)[1]}
NetDegree <- unname(sort(deg,decreasing=TRUE)[n])
bsk.network <- delete.vertices(bsk.network,which(degree(bsk.network)<NetDegree))

# Remove loops and multiple edges
bsk.network <- simplify(bsk.network, remove.multiple = remove.multiple, remove.loops = noloops) 

# delete not linked vertices
if (isTRUE(remove.isolates)){

bsk.network <- delete.isolates(bsk.network, mode = 'in')}

# Choose Network layout
l <- layout.kamada.kawai(bsk.network) #default
switch(type,
       circle={l <- layout.circle(bsk.network)},
       sphere={l <- layout.sphere(bsk.network)},
       mds={l <- layout.mds(bsk.network)},
       fruchterman={l <- layout.fruchterman.reingold(bsk.network)},
       kamada={l <- layout.kamada.kawai(bsk.network)},
       vosviewer={
         if (is.null(vos.path)){vos.path=getwd()}
         if (sum(dir(vos.path) %in% "VOSviewer.jar")==0){cat(paste("VOSviewer.jar does not exist in the path",vos.path,"\n\nPlese download it from http://www.vosviewer.com/download","\n(Java version for other systems)\n"))}
         else{
         netfile=paste(vos.path,"/","vosnetwork.net",sep="")
         VOScommand=paste("java -jar ",vos.path,"/","VOSviewer.jar -pajek_network ",netfile,sep="")
         write.graph(graph = bsk.network, file = netfile, format = "pajek")
         system(VOScommand)}
         })



if (type!="vosviewer"){
  
  switch(cluster,
         null={V(bsk.network)$color="#8DD3C7"},
         optimal={
           net_groups <- cluster_optimal(bsk.network)
           V(bsk.network)$color <- brewer.pal(12, 'Set3')[membership(net_groups)]},
         louvain={
           net_groups <- cluster_louvain(bsk.network)
           V(bsk.network)$color <- brewer.pal(12, 'Set3')[membership(net_groups)]},
         infomap={
           net_groups <- cluster_infomap(bsk.network)
           V(bsk.network)$color <- brewer.pal(12, 'Set3')[membership(net_groups)]},
         edge_betweenness={
           net_groups <- cluster_edge_betweenness(bsk.network)
           V(bsk.network)$color <- brewer.pal(12, 'Set3')[membership(net_groups)]},
         walktrap={
           net_groups <- cluster_walktrap(bsk.network)
           V(bsk.network)$color <- brewer.pal(12, 'Set3')[membership(net_groups)]}
         )
  
## Plot the network
  
  if (!is.null(weighted)){
    E(bsk.network)$width <- (E(bsk.network)$weight + min(E(bsk.network)$weight))/max(E(bsk.network)$weight + min(E(bsk.network)$weight)) *edgesize
  } else {E(bsk.network)$width=edgesize}
  

  if (isTRUE(halo) & cluster!="null"){
    plot(net_groups,bsk.network,layout = l, edge.curved=curved, vertex.label.dist = 0.4, vertex.frame.color = 'black', vertex.label.color = 'black', vertex.label.font = 1, vertex.label = V(bsk.network)$name, vertex.label.cex = labelsize, main=Title)
  } else{
    plot(bsk.network,layout = l, edge.curved=curved, vertex.label.dist = 0.4, vertex.frame.color = 'black', vertex.label.color = 'black', vertex.label.font = 1, vertex.label = V(bsk.network)$name, vertex.label.cex = labelsize, main=Title)
  }

}  


return(bsk.network)}

delete.isolates <- function(graph, mode = 'all') {
  isolates <- which(degree(graph, mode = mode) == 0) - 1
  delete.vertices(graph, names(isolates))
  }

