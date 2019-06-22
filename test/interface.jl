# Implement the interface for breadth first in a dummy way
struct DummyBreadthFirstSearch <: AbstractBreadthFirstSearch{Symbol} end

@testset "Forced implementations" begin
    search = DummyBreadthFirstSearch()
    tree = BPTree("Dummy data")

    @test_throws MissingImplementationError BranchAndPrune.bisect(search, "Dummy element")
    @test_throws MissingImplementationError BranchAndPrune.process(search, tree)

    # TODO add test for get_leaf_id! and insert_leaf! for general searches
    # TODO add test for keyfunc for AbstractKeySearch
end

BranchAndPrune.process(::DummyBreadthFirstSearch, s::Symbol) = s, s
BranchAndPrune.bisect(::DummyBreadthFirstSearch, s::Symbol) = :store, :store

# TODO Add similar tests for depth first and key search
@testset "Breadth first search" begin
    #= Build the following tree for testing
                    (1)
                   /   \
                (2)     (5: to_bisect)
               /   \
    (3: to_store)  (4: to_discard)
    =#
    rt = BPNode(0, [2, 5])
    node = BPNode(1, [3, 4])
    to_store = BPLeaf(:store, 2, :working)
    to_discard = BPLeaf(:discard, 2, :working)
    to_bisect = BPLeaf(:bisect, 1, :working)

    tree = BPTree(Dict(1 => rt, 2 => node),
                  Dict(3 => to_store, 4 => to_discard, 5 => to_bisect),
                  [3, 4, 5])

    search = DummyBreadthFirstSearch()

    # First iteration processes the to_store leaf
    tree, _ = iterate(search, tree)

    @test nnodes(tree) == 5
    @test tree[3].status == :final
    @test length(tree.working_leaves) == 2

    # Second iteration processes the to_discard leaf
    tree, _ = iterate(search, tree)

    @test nnodes(tree) == 4
    @test length(tree.working_leaves) == 1

    # Second iteration processes the to_bisect leaf
    tree, _ = iterate(search, tree)

    @test nnodes(tree) == 6
    @test length(tree.working_leaves) == 2
    @test isa(tree[5], BPNode)
end
