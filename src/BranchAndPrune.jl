module BranchAndPrune

using AbstractTrees

include("tree.jl")
export regions, finished_regions, unfinished_regions

include("search_order.jl")
export SearchOrder, BreadthFirst, DepthFirst, ChangingOrder
export push!, pop!, set_next!

include("search.jl")
export BranchAndPruneSearch, SearchState, BranchAndPruneResult, bpsearch

end  # module