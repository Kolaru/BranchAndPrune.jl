"""
    SearchOrder

Abstract type representing the order of processing during a branch and
prune search.

For custom search orders following methods must be implemented:
- `pop!(so::SearchOrder)`: return the next leaf to be processed.
    Return `nothing` when the search is done.
- `push!(so::SearchOrder, leaf::BPNode)`: add a leaf to the set of leaves to be
    processed.

The object is initialized by giving it the root node of the search tree,
as `SearchOrder(root::BPNode)`.
"""
abstract type SearchOrder end

struct DepthFirst{REGION} <: SearchOrder
    working_leaves::Vector{BPNode{REGION}}
end

DepthFirst(root::BPNode) = DepthFirst([root])

struct BreadthFirst{REGION} <: SearchOrder
    working_leaves::Vector{BPNode{REGION}}
end

BreadthFirst(root::BPNode) = BreadthFirst([root])

"""
    pop!(::SearchOrder)

Return the next leaf that will be processed.

Can modify the internal state of the SearchOrder.

Must return `nothing` if there is no more data to process.

Must be define for custom search orders.
"""
Base.pop!(so::BreadthFirst) = isempty(so.working_leaves) ? nothing : popfirst!(so.working_leaves)
Base.pop!(so::DepthFirst) = isempty(so.working_leaves) ? nothing : pop!(so.working_leaves)

"""
    push!(::SearchOrder, leaf::BPNode)

Add a leaf to the set of nodes that need to be processed.

Can modify the internal state of the SearchOrder.

Must be define for custom search orders.
"""
Base.push!(so::Union{DepthFirst, BreadthFirst}, leaf::BPNode) = push!(so.working_leaves, leaf)
