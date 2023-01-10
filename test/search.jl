@testset "search.jl" begin
    # 23 in a sorted list
    function process(list)
        if length(list) == 1
            only(list) == 23 && return :store, list
            return :prune, list
        end

        if last(list) < 23 || first(list) > 23
            return :prune, list
        end

        return :branch, list
    end

    function bisect(list)
        mid = div(length(list), 2)
        return list[1:mid], list[(mid+1):end]
    end

    a = [1, 2, 4, 9, 10, 11, 17, 22, 23, 29, 37, 102]
    
    for SearchOrder in (BreadthFirst, DepthFirst)
        search = BranchAndPruneSearch(BreadthFirst, process, bisect, a)
        res = bpsearch(search)

        @test res.converged == true
        @test length(res.final_regions) == 1
        @test only(res.final_regions)[1] == 23
        @test isempty(res.unfinished_regions)
    end
end