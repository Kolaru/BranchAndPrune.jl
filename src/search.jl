"""
    BranchAndPruneSearch(S, process, bisect, initial_region)

Branch and prune search, using the search order `S` on the given initial region.

`process` and `bisect` are used to perform the search in the searched regions.
They both take a single region as an argument.

`process` must return an action to perform and the region on which
to perform it. The possible actions are
    - `:stop`: the region is considered as final, is stored, and is not
        further processed.
    - `:branch`: the element is bisected and each of the two resulting part
        are processed independently.
    - `:prune`: the element is discarded from the tree.
        If it is the last descendant of a branch, the whole branch is pruned
        from the tree.
The initial region can be returned unchanged if no refinement is possible at
this stage.

`bisect` is used when a region is marked to be branched.
It must return two subregions of the original one.

`BranchAndPruneSearch` objects are iterable, exhausting the iterable
performs the full search.

WARNING
By default, the search only ends when all remaining regions are given the
directive `:stop` by the process function.
For early stopping, either manually break the iteration loop, or use
the function `bpsearch(callback, search)`.
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

struct SearchState{S, REGION}
    search_order::S
    tree::BPNode{REGION}
    final_leaves::Vector{BPNode{REGION}}
end

function SearchState(S, initial_region::REGION) where REGION
    root = BPNode(:working, initial_region, nothing, :left)
    return SearchState(S(root), root, BPNode{REGION}[])
end

function Base.iterate(
        bp::BranchAndPruneSearch{S},
        state = SearchState(S, bp.initial_region)) where S

    search = state.search_order
    isempty(working_leaves(search)) && return nothing

    node = pop!(search)
    action, region = bp.process(node.region)
    if action == :stop
        node.region = region
        node.status = :final
        push!(state.final_leaves, node)
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
              "Valid actions are :stop, :branch and :prune.")
    end
    return state, state
end

struct BranchAndPruneResult{S, REGION}
    search_order::S
    initial_region::REGION
    tree::BPNode{REGION}
    final_regions::Vector{REGION}
    unfinished_regions::Vector{REGION}
    converged::Bool
end

# TODO Docstring
function bpsearch(
        bp::BranchAndPruneSearch{<:Any, REGION} ;
        callback = (state -> false),
        simplify = true) where REGION
    endstate = nothing

    for state in bp
        endstate = state
        callback(state) && break
    end

    unfinished_leaves = working_leaves(endstate.search_order)

    if simplify
        simplify_tree!(endstate.tree)
    end

    return BranchAndPruneResult(
        endstate.search_order,
        bp.initial_region,
        endstate.tree,
        REGION[leaf.region for leaf in endstate.final_leaves],
        REGION[leaf.region for leaf in unfinished_leaves],
        isempty(unfinished_leaves)
    )
end