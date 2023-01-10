# BranchAndPrune.jl

This package aims at providing an interface for branch and prune search in Julia.

## Branch and prune

A branch and prune algorithm has the following general structure:

1. Consider one region of the search space.
2. Determine status of this search region, with three possible outcomes:
   1. The region does not contain anything of interest. In this case discard the region (*prune* it).
   2. The region is in a state that does not require further processing (for example a given tolerance has been met). In this case it is stored.
   3. None of the above. In this case, the region is bisected and each of the subregions created is added to the pool of regions to be considered (creating new *branches* for the search).
3. Go back to 1.

Also this was developped to meet the need of the [`IntervalRootFinding.jl`](https://github.com/JuliaIntervals/IntervalRootFinding.jl) package, and as such it constitutes a concrete example of possible usage.


## Usage example

As an example we are looking for zero of monotonic functions, `f(x) = 0`.

We work with tuple of numbers `(a, b)` to represent intervals.

First we define the `process` function. The logic is as follow
- if the image of both side of the interval have the same sign, then the interval does not contain a solution (since `f` is monotonic) and we discard the interval.
- if the size of the interval is small enough, we store it.
- otherwise, we bisect it.

In all cases, we do not modify the interval when processing it.

```jl
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
```

Then we define how an interval is bisected.

```jl
function bisect((a, b))
    m = (a + b)/2  # The midpoint
    return (a, m), (m, b)
end
```

Note the difference between `process` and `bisect`. `bisect` only act on the search regions, independantly of the problem we are trying to solve, while `process` is responsible for everything related to actually solving the problem (by looking at the behavior of `f` in the example).

Finally we perform the search, by defining the function of interest and the search object, and passing it to `bpsearch`.

```jl
f(x) = x/3 + 5  # Exact solution is -15
search = BranchAndPruneSearch(BreadthFirst, X -> process(f, X), bisect, (-30.0, 20.0))
bpsearch(search)
```

Returning a correct enclosure of the solution

```
BranchAndPruneResult
 converged: true
 initial region: (-30.0, 20.0)
 final regions:
  (-15.00000000349246, -14.999999997671694)
```

Using a callback it is possible to stop the iteration early

```jl
sol = bpsearch(search ; callback = state -> state.iteration >= 10)
```

In this case no region hit the finalized state, and the search is considered unconverged.

```jl
julia> sol = bpsearch(search ; callback = state -> state.iteration >= 25)
BranchAndPruneResult
 converged: false
 initial region: (-30.0, 20.0)
 final regions:

 unfinished regions:
  (-15.009765625, -15.003662109375)
  (-15.003662109375, -14.99755859375)
  (-14.99755859375, -14.9853515625)
```

The tree representing the current state of the search can be examined.

```jl
julia> sol.tree
Branching
├─ Branching
│  ├─ (:working, (-15.009765625, -15.003662109375))
│  └─ (:working, (-15.003662109375, -14.99755859375))
└─ (:working, (-14.99755859375, -14.9853515625))
```

Using a `DepthFirstSearch` order instead, we see a different intermediate result and tree.
As expected, using a depth first search produces a much deeper tree.

```jl
julia> search = BranchAndPruneSearch(DepthFirst, X -> process(f, X), bisect, (-30.0, 20.0))
BranchAndPruneSearch{DepthFirst, Tuple{Float64, Float64}, var"#91#92", typeof(bisect)}(var"#91#92"(), bisect, (-30.0, 20.0))

julia> sol = bpsearch(search ; callback = state -> state.iteration >= 25)
BranchAndPruneResult
 converged: false
 initial region: (-30.0, 20.0)
 final regions:

 unfinished regions:
  (-30.0, -17.5)
  (-17.5, -15.9375)
  (-15.9375, -15.15625)
  (-15.15625, -15.05859375)
  (-15.05859375, -15.009765625)
  (-15.009765625, -15.003662109375)
  (-15.003662109375, -15.0006103515625)
  (-15.0006103515625, -14.999847412109375)
  (-14.999847412109375, -14.99908447265625)


julia> sol.tree
Branching
├─ (:working, (-30.0, -17.5))
└─ Branching
   ├─ (:working, (-17.5, -15.9375))
   └─ Branching
      ├─ (:working, (-15.9375, -15.15625))
      └─ Branching
         ├─ (:working, (-15.15625, -15.05859375))
         └─ Branching
            ├─ (:working, (-15.05859375, -15.009765625))
            └─ Branching
               ⋮
```