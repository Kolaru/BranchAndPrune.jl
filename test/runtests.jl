using BranchAndPrune
using Test

import BranchAndPrune: BPLeaf, BPNode, BPTree, MissingImplementationError
import BranchAndPrune: discard_leaf!, newid, root

include("tree.jl")
include("interface.jl")
