"""
    BPNode{REGION}

Node of a `BPTree` containing some region.
Its status is one of
    - `:working`: for a leaf that need further processing.
    - `:final`: for a leaf in its final state.
    - `:node`: for an intermediate node that doesn't contain region.
"""
mutable struct BPNode{REGION}
    status::Symbol
    region::Union{Nothing, REGION}
    parent::Union{Nothing, BPNode{REGION}}
    is_left_child::Bool
    left_child::Union{Nothing, BPNode{REGION}}
    right_child::Union{Nothing, BPNode{REGION}}
end

function BPNode(status, region, parent, side)
    BPNode(status, region, parent, side == :left, nothing, nothing)
end

function prune!(node::BPNode)
    parent = node.parent

    if isnothing(parent)
        node.region = nothing
        node.status = :empty
        node.left_child = nothing
        node.right_child = nothing
    end

    if node.is_left_child
        isnothing(parent.right_child) && return prune!(parent)
        parent.left_child = nothing
    else
        isnothing(parent.left_child) && return prune!(parent)
        parent.right_child = nothing
    end
end