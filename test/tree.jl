@testset "Trivial tree" begin
    #= Manually create a simple tree with the following structure

        (1)
         |
        (2)
    =#
    leaf = BPLeaf("I'm a leaf", 1, :final)
    node = BPNode(0, [2])
    tree = BPTree(Dict(1 => node),
                  Dict(2 => leaf),
                  [2])

    # Check that printing does not error
    io = IOBuffer()
    println(io, leaf)
    println(io, node)
    println(io, tree)

    @test root(tree) == node
    @test nnodes(tree) == 2

    d = data(tree)
    @test length(d) == 1
    @test d[1] == "I'm a leaf"

    k = newid(tree)
    @test k ∉ 0:2  # The new ID must be new and not 0
    @test isa(k, Integer)

    discard_leaf!(tree, 2)
    # The last leaf was deleted so the tree should be empty
    @test nnodes(tree) == 0
end


@testset "Simple tree" begin
    #= Tests on a slighty less trivial tree

          (1)
         /   \
       (2)   (8)
      /  \     \
    (3)  (5)   (9)
     |   | \     \
    (4) (6) (7)  (10)
    =#

    n1 = BPNode(0, [2, 8])
    n2 = BPNode(1, [3, 5])
    n3 = BPNode(2, [4])
    n4 = BPLeaf("Leaf 4", 3, :working)
    n5 = BPNode(2, [6, 7])
    n6 = BPLeaf("Leaf 6", 5, :final)
    n7 = BPLeaf("Leaf 7", 5, :working)
    n8 = BPNode(1, [9])
    n9 = BPNode(8, [10])
    n10 = BPLeaf("Leaf 10", 9, :working)

    tree = BPTree(Dict(1 => n1, 2 => n2, 3 => n3, 5 => n5, 8 => n8, 9 => n9),
                  Dict(4 => n4, 6 => n6, 7 => n7, 10 => n10),
                  [3, 4, 8])

    # Check that printing does not error
    io = IOBuffer()
    println(io, tree)

    @test newid(tree) ∉ 0:10
    @test length(data(tree)) == 4

    @test nnodes(tree) == 10

    discard_leaf!(tree, 6)
    @test nnodes(tree) == 9

    discard_leaf!(tree, 4)
    @test nnodes(tree) == 7

    discard_leaf!(tree, 10)
    @test nnodes(tree) == 4

    @test length(data(tree)) == 1
end