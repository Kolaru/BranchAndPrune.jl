"""
    BPNode{DATA}

Node of a `BPTree` containing some data.
Its status is one of
    - `:working`: for a leaf that need further processing.
    - `:final`: for a leaf in its final state.
    - `:node`: for an intermediate node that doesn't contain data.
"""
struct BPNode{DATA}
    parent::Union{Nothing, BPNode{DATA}}
    children::Vector{BPNode{DATA}}
    data::Union{Nothing, DATA}
    status::Symbol
end



"""
    BPTree{DATA}

Tree storing the data used and produced by a branch and bound search in a
structured way.

Support the iterator interface. The element yielded by the iteration are
tuples `(node_id, lvl)` where `lvl` is the depth of the node in the tree.
"""
struct BPTree{DATA}
    root::BPNode{DATA}
end

function BPTree(rootdata::DATA) where {DATA}
    rootleaf = BPLeaf(rootdata, 0)
    BPTree{DATA}(Dict{Int, BPNode}(), Dict(1 => rootleaf), Int[1])
end

# TODO plain/text business to have valid repr
function show(io::IO, node::BPNode)
    if node.status == :node
        print(io, "Node with children $(node.children)")
    else
        print(io, "Leaf (:$(node.status)) with data $(node.data)")
    end
end

function show(io::IO, wt::BPTree{DATA}) where {DATA}
    println(io, "Working tree with $(nnodes(wt)) elements of type $DATA")

    if nnodes(wt) > 0
        println(io, "Indices: ", vcat(collect(keys(wt.nodes)), collect(keys(wt.leaves))) |> sort)
        println(io, "Structure:")
        for (id, lvl) in wt
            println(io, "  "^lvl * "[$id] $(wt[id])")
        end
    end
end

# Root node has id 1 and parent id 0
root(wt::BPTree) = wt[1]
is_root(::BPTree, id::Int) = (id == 1)

"""
    nnodes(wt::BPTree)

Number of nodes (including leaves) in a `BPTree`.
"""
nnodes(wt::BPTree) = length(wt.nodes) + length(wt.leaves)

"""
    data(leaf::BPLeaf)

Return the data stored in the leaf.
"""
data(leaf::BPLeaf) = leaf.data

"""
    data(wt::BPTree)

Return all the data stored in a `BPTree` as a list. The ordering of the elements
is arbitrary.
"""
data(wt::BPTree) = data.(values(wt.leaves))

function newid(wt::BPTree)
    k1 = keys(wt.nodes)
    k2 = keys(wt.leaves)

    if length(k1) > 0
        m1 = maximum(k1)
    else
        m1 = 0
    end

    if length(k2) > 0
        m2 = maximum(k2)
    else
        m2 = 0
    end

    return max(m1, m2) + 1
end

# Index operations (slower than manipulating the node directly in the correct
# dictionary)
function getindex(wt::BPTree, id)
    haskey(wt.nodes, id) && return wt.nodes[id]
    haskey(wt.leaves, id) && return wt.leaves[id]
    error("getindex failed: no index $id")  # TODO: make better error
end

setindex!(wt::BPTree, val::BPNode, id) = setindex!(wt.nodes, val, id)
setindex!(wt::BPTree, val::BPLeaf, id) = setindex!(wt.leaves, val, id)

function delete!(wt::BPTree, id)
    if haskey(wt.nodes, id)
        delete!(wt.nodes, id)
    elseif haskey(wt.leaves, id)
        delete!(wt.leaves, id)
    else
        error("delete! failed: no index $id")  # TODO: make better error
    end
end

"""
    discard_leaf!(wt::BPTree, id::Int)

Delete the `BPLeaf` with index `id` and all its ancestors to which it is
the last descendant.
"""
function discard_leaf!(wt::BPTree, id::Int)
    leaf = wt.leaves[id]
    delete!(wt.leaves, id)
    recursively_delete_parent!(wt, leaf.parent, id)
end

function recursively_delete_parent!(wt, id_parent, id_child)
    if !is_root(wt, id_child)
        parent = wt.nodes[id_parent]
        if length(parent.children) == 1  # The child has no siblings, so delete the parent
            delete!(wt.nodes, id_parent)
            recursively_delete_parent!(wt, parent.parent, id_parent)
        else  # The child has siblings so remove it from the children list
            deleteat!(parent.children, searchsortedfirst(parent.children, id_child))
        end
    end
end

function iterate(wt::BPTree, (id, lvl)=(0, 0))
    id, lvl = next_id(wt, id, lvl)
    lvl == 0 && return nothing
    return (id, lvl), (id, lvl)
end

function next_id(wt::BPTree, id, lvl)
    lvl == 0 && return (1, 1)
    node = wt[id]
    isa(node, BPNode) && return (node.children[1], lvl + 1)
    return next_sibling(wt, id, lvl)
end

function next_sibling(wt::BPTree, sibling, lvl)
    parent = wt[sibling].parent
    parent == 0 && return (0, 0)
    children = wt[parent].children
    maximum(children) == sibling && return next_sibling(wt, parent, lvl - 1)
    id = minimum(filter(x -> x > sibling, children))
    return (id, lvl)
end