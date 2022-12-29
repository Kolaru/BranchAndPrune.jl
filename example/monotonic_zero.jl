using BranchAndPrune

struct Interval
    lo::Float64
    hi::Float64
end

function process(f, interval, tol = 1e-8)
    ylo = f(interval.lo)
    yhi = f(interval.hi)

    # If both have the same sign they are on the same side of the zero
    if ylo*yhi > 0
        return :prune, interval
    elseif interval.hi - interval.lo < tol
        return :store, interval
    else
        return :branch, interval
    end
end

function bisect(interval)
    m = (interval.hi + interval.lo)/2
    return Interval(interval.lo, m), Interval(m, interval.hi)
end

function find_zero(f, interval)
    search = BranchAndPruneSearch(BreadthFirst, X -> process(f, X), bisect, interval)
    return bpsearch(search)
end

find_zero(x -> x/3 + 5, Interval(-20, 20))  # Exact solution is -15
find_zero(x -> (x - 4)^3 - 8, Interval(-20, 20))  # Exact solution is 6
