module BranchAndPrune

import Base: copy, eltype, iterate, IteratorSize, show
import Base: getindex, setindex!, delete!

export AbstractSearch, AbstractBreadthFirstSearch, AbstractDepthFirstSearch
export data
export copy, eltype, iterate, IteratorSize, nnodes

include("tree.jl")
include("search.jl")
include("forced_definitions.jl")

end  # module