using BranchAndPrune
using AbstractTrees
using Test

import BranchAndPrune: BPNode, squash_node!, prune!

include("tree.jl")
include("search_order.jl")
include("search.jl")