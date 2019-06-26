# BranchAndPrune.jl

This package aims at providing an interface for branch and prune search in Julia.

## Branch and prune

A branch and prune algorithm has the following general structure:

1. Consider one region of the search space.
2. Determine status of this search region, with three possible outcomes:
   1. The region does not contain anything of interest. In this case discard the region (*prune* it).
   2. The region is in a state that does not require further processing (for example a given tolerance has been met). In this case it is stored.
   3. None of the above. In this case, the region is bisected (or multisected) and each of the subregions created is added to the pool of regions to be considered (creating new *branches* for the search).
3. Go back to 1.

Some examples, like a naive implementation of the bisection method for zero finding, can be found in the `example` folder.

Also this was developped to meet the need of the [`IntervalRootFinding.jl`](https://github.com/JuliaIntervals/IntervalRootFinding.jl) package, and as such it constitutes a more complex and concrete example of possible usage.


## Usage

### Subtyping searches with concrete strategy

The package defines three search strategies: breadth first, depth first and key search (i.e. a key is computed for each region and the region with the smallest key is processed first). These only determine in which order search regions are considered, but nothing more. In consequence, concrete search types must implement two things:

1. `BranchAndPrune.process` that determines the status of a search region, and
2. `BranchAndPrune.bisect` that bisect a search region.

To make things a bit clearer, we now show how to implement a simple bisection search for the zero of a continuous monotonic function (full implementation is available in `example/monotonic_zero.jl`).

First to be able to store search region we define an interval type

```jl
struct Interval
    lo::Float64
    hi::Float64
end
```

Then we need to create our own search type. Our search type contains the function whose zero is searched, an initial search region and an absolute tolerance to be used as stopping criterion.

```jl
struct ZeroSearch <: AbstractDepthFirstSearch{Interval}
    f::Function
    initial::Interval
    tol::Float64
end
```

We have subtyped the `AbstractDepthFirstSearch` which means that the first regions created will be considered first (first in first out). Also the abstract type takes the type of the search region as type parameter for efficiency reasons.

Note that by default, the initial search region is assumed to be the field `initial` of the type. This can however be customized by redifining the function `BranchAndPrune.root_element`.

To be able to perform the search, as mentioned above, we need to implement how search regions are handled. The `process` function should determine the status of an interval as follows:

1. If both bounds of the interval have the same sign, then the interval cannot contain zero and should be discarded.
2. If the radius of the interval is smaller than the tolerance, the interval should not be processed further, but instead stored.
3. Otherwise, we bisect the interval.

Concretely this reads

```jl
function BranchAndPrune.process(search::ZeroSearch, interval)
    ylo = search.f(interval.lo)
    yhi = search.f(interval.hi)

    if ylo*yhi > 0
        return :discard, interval
    elseif interval.hi - interval.lo < search.tol
        return :store, interval
    else
        return :bisect, interval
    end
end
```

Note the use of the symbols `:discard`, `:store` and `:bisect`. They determine the status of the search region and are the three only possible ones. There is also a second returned value, here always the interval considered without modification. In principle it could be a refinement of the search region as it replaces the initial one in the search.

Then we need to be able to bisect an interval, this can be done as follows

```jl
function BranchAndPrune.bisect(::ZeroSearch, interval)
    m = (interval.hi + interval.lo)/2
    return Interval(interval.lo, m), Interval(m, interval.hi)
end
```

We can now write a function to run the search given a function `f` and an initial interval

```jl
function run_search(f, interval)
    search = ZeroSearch(f, interval, 1e-10)

    local endtree = nothing

    for working_tree in search
        endtree = working_tree
    end

    return endtree
end
```

Several things are important here. First the search object is an iterator, to get the result it is thus necessary to iterate over it, for example with the `for` loop presented here. This means that some operations, like printing debug info, can be done at each iterations.

This also explains the need for the `local` keyword when initializing `endtree` this allows to extract the state from the `for` loop. Otherwise, the variable `endtree` would be shadowed inside the loop and the internal state could not be retrieved.

Finally the states of the search during the iteration, as well as the final state, are represented as a *tree* (of type `BPTree`). This closely matches the structure of the search as each bisection can be seen as creating a new branch in a binary tree.

Finally, the `data` function allows to get a list of all surviving search regions at the end of the search

```jl
tree = run_search(x -> (x - 4)^3 - 8, Interval(-20, 20))
d = data(tree)
```

Here `d` contains only one element, an interval that indeed well approximates the exact solution which is `6`. If the function had no zero, `d` would be empty.


### Search with custom strategy

The order in which search regions are considered can be customized by subtyping `AbstractSearch` directly and defining `BranchAndPrune.get_leaf_id!` and `BranchAndPrune.insert_leaf!` for the new type. This however requires some unerstanding of the internal tree structure.

Please refer to the docstrings and source code for more information, and don't hesitate to open an issue for information or clarifications.
