"""
TODO finish
For custom search orders following methods must be implemented:
- `working_leaves!(so::SearchOrder)`: return an iterable containing the
    leaves that are yet to be processed.
- `pop!(so::SearchOrder)`: return the next leaf to be processed and remove it
    from the set of working leaves.
- `push!(so::SearchOrder, leaf::BPNode)`: add a leaf to the set of working leaves.
"""
abstract type SearchOrder end

struct DepthFirst{REGION} <: SearchOrder
    working_leaves::Vector{PBNode{REGION}}
end

DepthFirst(root::BPNode) = DepthFirst([root])

struct BreadthFirst{REGION} <: SearchOrder
    working_leaves::Vector{PBNode{REGION}}
end

BreadthFirst(root::BPNode) = BreadthFirst([root])

"""
    pop!(::AbstractSearch, tree::BPTree)

Return the next leaf that will be processed and remove it from the
list of working leaves.

Must be define for custom search orders.
"""
pop!(so::DepthFirst) = popfirst!(so.working_leaves)
pop!(so::BreadthFirst) = pop!(so.working_leaves)

"""
    push!(::AbstractSearch, tree::BPTree, leaf::BPLeaf)

TODO

Must be define for custom search orders.
"""
push!(so::Union{DepthFirst, BreadthFirst}, leaf::BPLeaf) = push!(so.working_leaves, leaf)
