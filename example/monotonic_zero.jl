using BranchAndPrune

function process(f, (a, b), tol = 1e-8)
    ya = f(a)
    yb = f(b)
    # If both have the same sign their product is positive
    if ya * yb > 0
        return :prune, (a, b)
    elseif b - a < tol
        return :store, (a, b)
    else
        return :branch, (a, b)
    end
end

function bisect((a, b))
    m = (a + b)/2  # The midpoint
    return (a, m), (m, b)
end

function find_zero(f, interval)
    search = BranchAndPruneSearch(BreadthFirst, X -> process(f, X), bisect, interval)
    return bpsearch(search)
end

find_zero(x -> x/3 + 5, (-20.0, 20.0))  # Exact solution is -15
find_zero(x -> (x - 4)^3 - 8, (-20.0, 20.0))  # Exact solution is 6
