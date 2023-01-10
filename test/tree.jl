@testset "tree.jl" begin
    #= Tests on a simple tree

          (1)
         /   \
       (2)   (8)
      /  \     \
    (3)  (5)   (9)
     |   | \     \
    (4) (6) (7)  (10)
    =#

    root = BPNode(:branching, 1, nothing, :left)
    n2 = BPNode(:branching, 2, root, :left)
    n3 = BPNode(:branching, 3, n2, :left)
    n4 = BPNode(:final, 4, n3, :left)
    n5 = BPNode(:branching, 5, n2, :right)
    n6 = BPNode(:final, 6, n5, :left)
    n7 = BPNode(:final, 7, n5, :right)
    n8 = BPNode(:branching, 8, root, :right)
    n9 = BPNode(:branching, 9, n8, :right)
    n10 = BPNode(:final, 10, n9, :right)

    # Check that printing does not error
    io = IOBuffer()
    println(io, root)

    # Check the tree interface
    @test length(collect(Leaves(root))) == 4
    @test length(collect(PreOrderDFS(root))) == 10

    # Test other functions
    @test length(children(n5)) == 2
    @test length(children(n9)) == 1
    @test length(children(n7)) == 0

    squash_node!(n9)
    @test n8.right_child === n10

    prune!(n7, squash = false)
    @test length(children(n5)) == 1
    
    prune!(n4, squash = true)
    @test root.left_child === n5
end