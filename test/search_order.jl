@testset "search_order.jl" begin
    #= Tests on a simple tree

          (1)
         /   \
       (2)   (5)
      /  \
    (3)  (4)
    =#

    root = BPNode(:branching, 1, nothing, :left)
    n2 = BPNode(:branching, 2, root, :left)
    n3 = BPNode(:working, 3, n2, :left)
    n4 = BPNode(:working, 4, n2, :right)
    n5 = BPNode(:working, 5, root, :right)

    depth_first = DepthFirst(n5)
    push!(depth_first, n4)
    push!(depth_first, n3)
    @test pop!(depth_first) == n3
    @test pop!(depth_first) == n4
    @test pop!(depth_first) == n5
    @test isnothing(pop!(depth_first))

    breadth_first = BreadthFirst(n5)
    push!(breadth_first, n4)
    push!(breadth_first, n3)
    @test pop!(breadth_first) == n5
    @test pop!(breadth_first) == n4
    @test pop!(breadth_first) == n3
    @test isnothing(pop!(breadth_first))
end