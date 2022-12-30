"""
    BranchAndPruneSearch(S, process, bisect, initial_region)

Branch and prune search, using the search order `S` on the given initial region.
It works by recursively bisecting the regions of search with `bisect` until
all regions are found satisfactory according to `process`.
Build a binary tree relating the regions to each other as the search progress.

`process` and `bisect` both take a single region as an argument.

`process` must return an action to perform and the region on which
to perform it. The possible actions are
- `:store`: the region is considered as final, is stored, and is not
    further processed.
- `:branch`: the element is bisected and each of the two resulting part
    are processed independently.
- `:prune`: the element is discarded from the tree.
    If it is the last descendant of a branch, the whole branch is pruned
    from the tree.
    The intermediate nodes with a single descendant are also removed from the tree.
The initial region can be returned unchanged if no refinement is possible at
this stage.

`bisect` is used when a region is marked to be branched.
It must return two subregions of the original one, and of the same type.

`BranchAndPruneSearch` objects are iterable, exhausting the iterable
performs the full search.

WARNING
By default, the search only ends when all remaining regions are given the
directive `:store` by the process function.
For stopping based on different criterion, either manually break the iteration
loop or use `bpsearch(search ; callback)` with a custom callback function.
"""
struct BranchAndPruneSearch{S, REGION, F, G}
    process::F
    bisect::G
    initial_region::REGION
end

function BranchAndPruneSearch(S, process::F, bisect::G, initial_region::R) where {F, G, R}
    BranchAndPruneSearch{S, R, F, G}(process, bisect, initial_region)
end

Base.eltype(::Type{BPS}) where {S, REGION, BPS <: BranchAndPruneSearch{S, REGION}} = SearchState{S, REGION}
Base.IteratorSize(::Type{BPS}) where {BPS <: BranchAndPruneSearch} = Base.SizeUnknown()

"""
    SearchState{S, REGION}

State of a search by branch and prune.

Field
=====
- `search_order``::SearchOrder : The order in which the search is performed.
    Contains information about the state of the search.
    See `SearchOrder` for more details.
- `tree`::BPNode{REGION} : The current binary tree representing the search.
- `iteration`::Int
"""
struct SearchState{S, REGION}
    search_order::S
    tree::BPNode{REGION}
    iteration::Int
end

function SearchState(S, initial_region::REGION) where REGION
    root = BPNode(:working, initial_region, nothing, :left)
    return SearchState(S(root), root, 1)
end

function Base.iterate(
        bp::BranchAndPruneSearch{S},
        state = SearchState(S, bp.initial_region)) where S

    search = state.search_order

    node = pop!(search)
    isnothing(node) && return nothing

    action, region = bp.process(node.region)
    if action == :store
        node.region = region
        node.status = :final
    elseif action == :branch
        left_data, right_data = bp.bisect(region)
        node.region = nothing
        node.status = :branching
        node.left_child = BPNode(:working, left_data, node, :left)
        node.right_child = BPNode(:working, right_data, node, :right)
        push!(search, node.left_child)
        push!(search, node.right_child)
    elseif action == :prune
        prune!(node)
    else
        error("process function for the search return " *
              "unknown action :$action for region of type $(typeof(region)). " *
              "Valid actions are :store, :branch and :prune.")
    end

    new_state = SearchState(
        state.search_order,
        state.tree,
        state.iteration + 1
    )
    return new_state, new_state
end

"""
    BranchAndPruneResult

Type representing the result of a branch and prune search.

Fields
======
- `search_order::SearchOrder`
- `initial_region`
- `tree::BPNode`: Root of the search tree constructed during the search.
- `final_regions`: Vector of all the regions that have been labelled with `:store`
    during the search.
- `unfinished_regions`: Vector of all the regions that have been produced by
    bisection but never processed.
    Non empty only if the search is stopped early.
- `converged::Bool`: Whether the search has run up to the end.
"""
struct BranchAndPruneResult{S, REGION}
    search_order::S
    initial_region::REGION
    tree::BPNode{REGION}
    final_regions::Vector{REGION}
    unfinished_regions::Vector{REGION}
    converged::Bool
end

function BranchAndPruneResult(
        search_order,
        initial_region::REGION,
        tree::BPNode{REGION}) where REGION
    
    final_regions = REGION[leaf.region for leaf in Leaves(tree) if leaf.status == :final]
    unfinished_regions = REGION[leaf.region for leaf in Leaves(tree) if leaf.status == :working]

    return BranchAndPruneResult(
        search_order,
        initial_region,
        tree,
        final_regions,
        unfinished_regions,
        isempty(unfinished_regions)
    )
end

function padded_string(val  ; padding = 1, skip = 0)
    buffer = IOBuffer()
    show(buffer, MIME"text/plain"(), val)
    s = String(take!(buffer))
    pad = " "^padding
    lines = split(s, "\n")[1 + skip:end]
    return pad * join(lines, "\n" * pad)
end

function Base.show(io::IO, ::MIME"text/plain", res::BranchAndPruneResult)
    ctx = IOContext(io, :compact => true)
    println(io, "BranchAndPruneResult")
    println(io, " converged: $(res.converged)")
    print(io, " initial region: ")
    show(ctx, MIME"text/plain"(), res.initial_region)
    println(io)
    println(io, " final regions:\n", padded_string(res.final_regions ; skip = 1))
    if !res.converged
        println(io, " unfinished regions:\n", padded_string(res.unfinished_regions ; skip = 1))
    end
end

"""
    bpsearch(bp::BranchAndPruneSearch ; callback::Function)

Perform a branch and prune search and return its result as a BranchAndPruneResult.

A callback function can be given, which is called on the search state
at every iteration.
It must have signature `callback(state::SearchState)::Bool`.
If it return `true` the searched is stopped and return.
"""
function bpsearch(
        bp::BranchAndPruneSearch ;
        callback = (state -> false))
    endstate = nothing

    for state in bp
        endstate = state
        callback(state) && break
    end

    tree = endstate.tree

    # Remove the root node if it has a single child
    if length(children(tree)) == 1
        tree = only(children(tree))
        tree.parent = nothing
    end

    return BranchAndPruneResult(
        endstate.search_order,
        bp.initial_region,
        tree
    )
end