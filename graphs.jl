module Graphs

using StatsBase

export GraphVertex, NodeType, Person, Address,
       generate_random_graph, get_random_person, get_random_address, generate_random_nodes,
       convert_to_graph,
       bfs, check_euler, partition,
       graph_to_str, node_to_str,
       test_graph

#= Single graph vertex type.
Holds node value and information about adjacent vertices =#
mutable struct GraphVertex
  value
  neighbors ::Vector
end

# Types of valid graph node's values.
abstract type NodeType end

struct Person <: NodeType
  name :: String
end

struct Address <: NodeType
  streetNumber :: Int64
end


# Number of graph nodes.
# N = 800

# Number of graph edges.
# K = 10000


#= Generates random directed graph of size N with K edges
and returns its adjacency matrix.=#
function generate_random_graph(N::Int64, K::Int64)
    A = Array{Bool,2}(N, N)

    A .= false

    for i in sample(1:N*N, K, replace=false)
      row, col = ind2sub(size(A), i)
      A[row,col] = true
      A[col,row] = true
    end
    A
end

# Generates random person object (with random name).
function get_random_person()
  Person(randstring())
end

# Generates random address object (with street random number).
function get_random_address()
  Address(rand(1:100))
end

# Generates N random nodes (of random NodeType).
function generate_random_nodes(N::Int64)
  nodes = Array{NodeType, 1}(N)

  for i = 1:N
   nodes[i] = (rand() > 0.5 ? Graphs.get_random_person() : Graphs.get_random_address())
  end
  nodes
end

#= Converts given adjacency matrix (NxN)
  into list of graph vertices (of type GraphVertex and length N). =#
function convert_to_graph(A::Array{Bool, 2}, nodes::Array{NodeType, 1})
  N::Int64 = length(nodes)
  graph::Array{GraphVertex, 1} = map(n -> GraphVertex(n, GraphVertex[]), nodes)

  for i = 1:N, j = 1:N
      if A[i,j]
        push!(graph[i].neighbors, graph[j])
      end
  end
  graph
end

#= Groups graph nodes into connected parts. E.g. if entire graph is connected,
  result list will contain only one part with all nodes. =#
function partition(graph::Array{GraphVertex, 1})
  parts = []
  remaining = Set(graph)
  visited = bfs(remaining=remaining)
  push!(parts, Set(visited))

  while !isempty(remaining)
    new_visited = bfs(visited=visited, remaining=remaining)
    push!(parts, new_visited)
  end
  parts
end

#= Performs BFS traversal on the graph and returns list of visited nodes.
  Optionally, BFS can initialized with set of skipped and remaining nodes.
  Start nodes is taken from the set of remaining elements. =#
function bfs(;visited::Set=Set(), remaining::Set=Set(graph))
  first = next(remaining, start(remaining))[1]
  q = [first]
  push!(visited, first)
  delete!(remaining, first)
  local_visited = Set([first])

  while !isempty(q)
    v = pop!(q)



    update = function(n)
        push!(q, n)
        push!(visited, n)
        push!(local_visited, n)
        delete!(remaining, n)
    end
    
    update.(filter(n -> !(n in visited), v.neighbors))
    # , filter(n -> !(n in visited), v.neighbors))



    # for n in v.neighbors
    #   if !(n in visited)
    #   end
    # end
  end
  local_visited
end

#= Checks if there's Euler cycle in the graph by investigating
   connectivity condition and evaluating if every vertex has even degree =#
function check_euler(graph::Array{GraphVertex, 1})
  if length(partition(graph)) == 1
    return any(map(v -> isodd(length(v.neighbors)), graph))
  end
    "Graph is not connected"
end

# Optimization: separate methods for various types
format_node(node::Person) = "Person: $(node.name)\n"
format_node(node::Address) = "Street nr: $(node.streetNumber)\n"

#= Returns text representation of the graph consisiting of each node's value
   text and number of its neighbors. =#
function graph_to_str(graph::Array{GraphVertex, 1})
  graph_str = ""
  for v in graph
    graph_str *= "****\n"

    n = v.value
    node_str = format_node(n)

    graph_str *= node_str
    graph_str *= "Neighbors: $(length(v.neighbors))\n"
  end
  graph_str
end

#= Tests graph functions by creating 100 graphs, checking Euler cycle
  and creating text representation. =#
function test_graph()
  N::Int64 = 800

  # Number of graph edges.
  K::Int64 = 10000
  for i=1:100
    # global graph

    A::Array{Bool, 2} = generate_random_graph(N, K)
    nodes::Array{NodeType, 1} = generate_random_nodes(N)
    graph::Array{GraphVertex, 1} = convert_to_graph(A, nodes)

    str = graph_to_str(graph)
    # println(str)
    check_euler(graph)
    # println(check_euler())
  end
end

end

@time Graphs.test_graph()

# print(Graphs.generate_random_nodes())
# @code_warntype Graphs.generate_random_nodes()

# @code_warntype Graphs.test_graph()

# Profile.init()
# Profile.clear()
# @profile Graphs.test_graph() 
# Profile.print()
