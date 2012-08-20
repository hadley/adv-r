
parents <- function(x, to = emptyenv()) {
  stopifnot(is.environment(x))  
  if (identical(x, to)) return(x)
  
  c(x, parents(parent.env(x), to = to))
  
}
nodes <- function(x) vapply(x, environmentName, character(1))
edges <- function(x) matrix(c(x[-length(x)], x[-1]), ncol = 2)

g_parents <- parents(globalenv())
ns <- lapply(loadedNamespaces(), getNamespace)
n_parents <- lapply(ns, parents, to = globalenv())

g_nodes <- nodes(g_parents)
g_edges <- edges(g_nodes)

n_nodes <- lapply(n_parents, nodes)
n_edges <- lapply(n_nodes, edges)

nodes <- sort(union(g_nodes, unlist(n_nodes)))
edges <- rbind(g_edges, do.call("rbind", n_edges))

edges_df <- data.frame(edges, value = 1)
edges_df$X1 <- factor(edges_df$X1, levels = nodes)
edges_df$X2 <- factor(edges_df$X2, levels = nodes)

library(igraph)
adj_mat <- xtabs( ~ X1 + X2, edges_df)
g <- graph.adjacency(adj_mat, mode = "directed")

plot(g, layout = layout.fruchterman.reingold, vertex.label = nodes, vertex.shape = "rectangle", vertex.size = nchar(nodes) * 5)

# Also need to:
#  * colour by environment/namespace (use palette)
#  * adjust relative scaling