module BranchAndPrune

import Base: copy, eltype, iterate, IteratorSize, show
import Base: getindex, setindex!, delete!

export BreadthFirst, DepthFirst
export data
export copy, eltype, iterate, IteratorSize, nnodes

include("search_order.jl")
include("tree.jl")
include("search.jl")

end  # module