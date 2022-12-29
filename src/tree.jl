"""
    BPNode(status, region, parent, is_left_child, left_child, right_child)

Node of a binary tree designed for branch and prune search.
It represents a search region and its status.

Its status is one of
- `:working`: for a leaf that need further processing.
- `:final`: for a leaf in its final state.
- `:branching`: for an intermediate node. In this case the data about the
    represented region is not stored in the node, but in its descendents.
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

Base.show(io::IO, ::MIME"text/plain", tree::BPNode) = print_tree(io, tree) 

"""
    prune!(node::BPNOde ; squash = true)

Remove the node from the tree, and recursively all branching nodes
that are left without descendant.

If `squash` is true, modify the tree to skip intermediate branching node
with a single descendant.
"""
function prune!(node::BPNode ; squash = true)
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
    squash && return squash_node!(parent)
end

squash_node!(::Nothing) = nothing

function squash_node!(node::BPNode)
    parent = node.parent
    isnothing(parent) && return
    child = only(children(node))

    if node.is_left_child
        parent.left_child = child
        child.is_left_child = true
        child.parent = parent
    else
        parent.right_child = child
        child.is_left_child = false
        child.parent = parent
    end
end

# AbstractTree.jl API
function AbstractTrees.children(node::BPNode{REGION}) where REGION
    if isnothing(node.left_child)
        isnothing(node.right_child) && return BPNode{REGION}[]
        return [node.right_child]
    else
        isnothing(node.right_child) && return [node.left_child]
        return [node.left_child, node.right_child]
    end
end

AbstractTrees.nodevalue(node::BPNode) = (node.status, node.region)

AbstractTrees.ParentLinks(::Type{<:BPNode}) = StoredParents()
AbstractTrees.parent(node::BPNode) = node.parent

AbstractTrees.NodeType(::Type{<:BPNode}) = HasNodeType()
AbstractTrees.nodetype(::Type{T}) where {T <: BPNode} = T

function AbstractTrees.printnode(io::IO, node::BPNode)
    if node.status == :branching
        print(io, "Branching")
    else
        print(io, nodevalue(node))
    end
end