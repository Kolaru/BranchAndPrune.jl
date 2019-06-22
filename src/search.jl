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

Subtyping `AbstractSearch` directly allows to have control over the order in which
the elements are process. To do this the following methods must be implemented:
  - `root_element(::AbstractSearch)`: return the first element to be processed. Use
        to build the initial tree.
  - `get_leaf_id!(::AbstractSearch, wt::BPTree)`: return the id of the next leaf that
        will be processed and remove it from the list of working leaves of `wt`.
  - `insert_leaf!(::AbstractSearch, wt::BPTree, leaf::BPLeaf)`: insert a leaf in the
        list of working leaves.

# Valid symbols returned by the process function
  - `:store`: the element is considered as final and is stored, it will not be
        further processed
  - `:bisect`: the element is bisected and each of the two resulting part will
        be processed
  - `:discard`: the element is discarded from the tree, allowing to free memory
"""
abstract type AbstractSearch{DATA} end

abstract type AbstractBreadthFirstSearch{DATA} <: AbstractSearch{DATA} end
abstract type AbstractDepthFirstSearch{DATA} <: AbstractSearch{DATA} end


# TODO should be smallest key first to match sort functions
"""
    AbstractKeySearch{DATA} <: AbstractSearch{DATA}

Interface to a branch and bound search that use a key function to decide which
element to process first. The search process first the element with the largest
key as computed by `keyfunc(ks::AbstractKeySearch, elem)`.

!!! warning
    Untested.
"""
abstract type AbstractKeySearch{DATA} <: AbstractSearch{DATA} end

"""
    root_element(search::AbstractSearch)

Return the initial element of the search. The `BPTree` will be build around it.

Can be define for custom searches that are direct subtype of `AbstractSearch`, default
behavior is to fetch the field `initial` of the search.
"""
root_element(search::AbstractSearch) = search.initial

"""
    get_leaf_id!(::AbstractSearch, wt::BPTree)

Return the id of the next leaf that will be processed and remove it from the
list of working leaves.

Must be define for custom searches that are direct subtype of `AbstractSearch`.
"""
get_leaf_id!(::AbstractBreadthFirstSearch, wt::BPTree) = popfirst!(wt.working_leaves)
get_leaf_id!(::AbstractDepthFirstSearch, wt::BPTree) = pop!(wt.working_leaves)
get_leaf_id!(::AbstractKeySearch, wt::BPTree) = popfirst!(wt.working_leaves)

"""
    insert_leaf!(::AbstractSearch, wt::BPTree, leaf::BPLeaf)

Insert the id of a new leaf that has been produced by bisecting an older leaf
into the list of working leaves.

Must be define for custom searches that are direct subtype of `AbstractSearch`.
"""
function insert_leaf!(::Union{AbstractBreadthFirstSearch{DATA}, AbstractDepthFirstSearch{DATA}},
                      wt::BPTree{DATA}, leaf::BPLeaf{DATA}) where {DATA}
    id = newid(wt)
    wt.leaves[id] = leaf
    push!(wt.working_leaves, id)
    return id
end

function insert_leaf!(::KS, wt::BPTree{DATA}, leaf::BPLeaf{DATA}) where {DATA, KS <: AbstractKeySearch{DATA}}
    id = newid(wt)
    wt.leaves[id] = leaf
    keys = keyfunc.(KS, wt.working_leaves)
    current = keyfunc(KS, leaf)

    # Keep the working_leaves sorted
    insert!(wt.working_leaves, searchsortedfirst(keys, current), id)
    return id
end

eltype(::Type{BPS}) where {DATA, BPS <: AbstractSearch{DATA}} = BPTree{DATA}
IteratorSize(::Type{BPS}) where {BPS <: AbstractSearch} = Base.SizeUnknown()

function iterate(search::AbstractSearch{DATA},
                 wt::BPTree=BPTree(root_element(search))) where {DATA}

    isempty(wt.working_leaves) && return nothing

    id = get_leaf_id!(search, wt)
    X = wt.leaves[id]
    action, newdata = process(search, data(X))
    if action == :store
        wt.leaves[id] = BPLeaf(newdata, X.parent, :final)
    elseif action == :bisect
        child1, child2 = bisect(search, newdata)
        leaf1 = BPLeaf(child1, id, :working)
        leaf2 = BPLeaf(child2, id, :working)
        id1 = insert_leaf!(search, wt, leaf1)
        id2 = insert_leaf!(search, wt, leaf2)
        wt.nodes[id] = BPNode(X, id1, id2)
        delete!(wt.leaves, id)
    elseif action == :discard
        discard_leaf!(wt, id)
    else
        error("Branch and bound: process function of the search object return " *
              "unknown action: $action for element $X. Valid actions are " *
              ":store, :bisect and :discard.")
    end
    return wt, wt
end