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
`bpsearch(callback, search)`.
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
- search_order::SearchOrder : The order in which the search is performed.
    Contains information about the state of the search. See `SearchOrder`
    for more details.
- tree::BPNode{REGION} : The current binary tree representing the search.
    It is mutated as the search progress.
- final_leaves::Vector{BPNode{REGION}}
"""
struct SearchState{S, REGION}
    search_order::S
    tree::BPNode{REGION}
end

function SearchState(S, initial_region::REGION) where REGION
    root = BPNode(:working, initial_region, nothing, :left)
    return SearchState(S(root), root)
end

function Base.iterate(
        bp::BranchAndPruneSearch{S},
        state = SearchState(S, bp.initial_region)) where S

    search = state.search_order

    node = pop!(search)
    isnothing(node) && return nothing

    action, region = bp.process(node.region)
    if action == :stop
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
        println(io)
        println(io, " unfinished regions:\n", padded_string(res.unfinished_regions ; skip = 1))
    end
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

    if simplify
        simplify_tree!(endstate.tree)
    end

    return BranchAndPruneResult(
        endstate.search_order,
        bp.initial_region,
        endstate.tree
    )
end