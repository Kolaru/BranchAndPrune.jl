using BranchAndPrune

struct Interval
    lo::Float64
    hi::Float64
end

# Search the zero of a monotonic function
struct ZeroSearch <: AbstractDepthFirstSearch{Interval}
    f::Function
    initial::Interval
    tol::Float64
end

function BranchAndPrune.process(search::ZeroSearch, interval)
    ylo = search.f(interval.lo)
    yhi = search.f(interval.hi)

    # If both have the same time they are on the same side of the zero
    if ylo*yhi > 0
        return :discard, interval
    elseif interval.hi - interval.lo < search.tol
        return :store, interval
    else
        return :bisect, interval
    end
end

function BranchAndPrune.bisect(::ZeroSearch, interval)
    m = (interval.hi + interval.lo)/2
    return Interval(interval.lo, m), Interval(m, interval.hi)
end

function find_zero(f, interval)
    search = ZeroSearch(f, interval, 1e-10)

    local endtree = nothing
    niter = 0

    for wt in search
        endtree = wt
        niter += 1
    end

    println("Search finished in $niter iterations.")
    d = data(endtree)  # Retrieve the data from the tree
    if length(d) == 0
        println("The function has no zero.")
    else
        # If there is a zero, the tree will have only one data available
        z = [1]
        println("The function has a zero in the interval [$(z.lo), $(z.hi)].")
    end
end

find_zero(x -> x/3 + 5, Interval(-20, 20))  # Exact solution is -15
find_zero(x -> (x - 4)^3 - 8, Interval(-20, 20))  # Exact solution is 6