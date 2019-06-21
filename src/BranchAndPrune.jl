module BranchAndPrune

import Base: copy, eltype, iterate, IteratorSize, show
import Base: getindex, setindex!, delete!

export BPSearch, BreadthFirstBPSearch, DepthFirstBPSearch
export data
export copy, eltype, iterate, IteratorSize, nnodes

include("tree.jl")
include("search.jl")
include("forced_definitions.jl")

# TODO Write documentation -> put in readme for now
# TODO Write benchmarks

end  # module