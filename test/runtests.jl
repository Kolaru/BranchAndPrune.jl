using BranchAndPrune
using Test

import BranchAndPrune: BPNode, BPTree, MissingImplementationError
import BranchAndPrune: discard_leaf!, newid, root

include("tree.jl")
