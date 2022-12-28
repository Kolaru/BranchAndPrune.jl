"""
TODO finish
For custom search orders following methods must be implemented:
- `pop!(so::SearchOrder)`: return the next leaf to be processed and remove it
    from the set of working leaves. Return `nothing` when the search is done.
- `push!(so::SearchOrder, leaf::BPNode)`: add a leaf to the set of working leaves.
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
    pop!(::AbstractSearch, tree::BPTree)

Return the next leaf that will be processed and remove it from the
list of working leaves. Must `nothing` if there is no more data to process
and the search should stop.

Must be define for custom search orders.
"""
Base.pop!(so::DepthFirst) = isempty(so.working_leaves) ? nothing : popfirst!(so.working_leaves)
Base.pop!(so::BreadthFirst) = isempty(so.working_leaves) ? nothing : pop!(so.working_leaves)

"""
    push!(::AbstractSearch, tree::BPTree, leaf::BPNode)

TODO

Must be define for custom search orders.
"""
Base.push!(so::Union{DepthFirst, BreadthFirst}, leaf::BPNode) = push!(so.working_leaves, leaf)
