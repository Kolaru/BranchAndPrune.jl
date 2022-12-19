"""
TODO finish
The following methods must be implemented:
  - `pop_leaf!(::SearchOrder, tree::BPTree)`: return the id of the next leaf that
        will be processed and remove it from the list of working leaves of `tree`.
  - `push_leaf!(::AbstractSearch, tree::BPTree, leaf::BPLeaf)`: insert a leaf in the
        list of working leaves.
"""
abstract type SearchOrder end

struct DepthFirst{DATA} <: SearchOrder
    working_leaves::Vector{PBNode{DATA}}
end

DepthFirst(root::BPNode) = DepthFirst([root])

struct BreadthFirst{DATA} <: SearchOrder
    working_leaves::Vector{PBNode{DATA}}
end

BreadthFirst(root::BPNode) = BreadthFirst([root])


"""
    root_element(search::AbstractSearch)

Return the initial element of the search. The `BPTree` will be build around it.

Can be define for custom searches that are direct subtype of `AbstractSearch`, default
behavior is to fetch the field `initial` of the search.
"""
root_element(search::AbstractSearch) = search.initial

"""
    pop_leaf!(::AbstractSearch, tree::BPTree)

Return the next leaf that will be processed and remove it from the
list of working leaves.

Must be define for custom search orders.
"""
pop_leaf!(so::DepthFirst) = popfirst!(so.working_leaves)
pop_leaf!(so::BreadthFirst) = pop!(so.working_leaves)

"""
    push_leaf!(::AbstractSearch, tree::BPTree, leaf::BPLeaf)

Insert the id of a new leaf that has been produced by bisecting an older leaf
into the list of working leaves.

Must be define for custom search orders.
"""
push_leaf!(so::Union{DepthFirst, BreadthFirst}, leaf::BPLeaf) = push!(so.working_leaves, leaf)

"""
    AbstractSearch{DATA}

Branch and bound search interface in element of type DATA.

This interface provide an iterable that perform the search.

There is currently three types of search supported `BreadFirstAbstractSearch`,
`AbstractDepthFirstSearch` and `AbstractKeySearch`, each one processing the element of the
tree in a different order. When subtyping one of these, the following methods
must be implemented:
  - `root_element(::AbstractSearch)`: return the element with which the search is started
  - `process(::AbstractSearch, elem::DATA)`: return a symbol representing the action
        to perform with the element `elem` and an object of type `DATA` representing
        the state of the element after processing (may return `elem` unchanged).
  - `bisect(::AbstractSearch, elem::DATA)`: return two elements of type `DATA` build
        by bisecting `elem`

# Valid symbols returned by the process function
  - `:store`: the element is considered as final and is stored, it will not be
        further processed
  - `:bisect`: the element is bisected and each of the two resulting part will
        be processed
  - `:discard`: the element is discarded from the tree, allowing to free memory
"""
abstract type AbstractSearch{DATA} end

struct BPSearch{DATA, S, F, G}
    search_order::S
    process::F
    bisect::G
    tree::BPTree{DATA}
end

function BPSearch(
        ::Type{S},
        process,
        bisect,
        root_data::DATA) where {S <: SearchOrder, DATA}
    
    root = BPNode(Nothing, BPNode{DATA}[], root_data, :working)
    push_leaf!(search_order, root)
    BPSearch(S(root), process, bisect, BPTree(root))
end

eltype(::Type{BPS}) where {DATA, BPS <: AbstractSearch{DATA}} = BPTree{DATA}
IteratorSize(::Type{BPS}) where {BPS <: AbstractSearch} = Base.SizeUnknown()

push_leaf!(search::BPSearch, leaf) = push_leaf!(search.search_order, leaf)
pop_leaf!(search::BPSearch) = pop_leaf!(search.search_order)

function iterate(search::BPSearch,
                 tree::BPTree=BPTree(root_element(search)))

    isempty(tree.working_leaves) && return nothing

    leaf = pop_leaf!(search)
    action, processed = search.process(leaf.data)
    if action == :store
        tree.leaves[id] = BPLeaf(processed, leaf.parent, :final)
    elseif action == :bisect
        child1, child2 = bisect(search, newdata)
        leaf1 = BPLeaf(child1, id, :working)
        leaf2 = BPLeaf(child2, id, :working)
        id1 = push_leaf!(search, leaf1)
        id2 = push_leaf!(search, leaf2)
        tree.nodes[id] = BPNode(X, id1, id2)
        delete!(tree.leaves, id)
    elseif action == :discard
        discard_leaf!(tree, id)
    else
        error("Branch and bound: process function of the search object return " *
              "unknown action: $action for element $X. Valid actions are " *
              ":store, :bisect and :discard.")
    end
    return tree, tree
end
