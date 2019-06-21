using BranchAndPrune
using Primes

# Search a given number in a sequence of sorted numbers
# Note: this is not optimal for the search, as each subsequence will be
# examinated whether or not the number is found.

struct SequenceSearch <: DepthFirstBPSearch{Vector{Int}}
    initial::Vector{Int}
    target::Int
end


function BranchAndPrune.process(search::SequenceSearch, seq)
    if length(seq) == 1
        if seq[1] == search.target
            return :store, seq
        else
            return :discard, seq
        end
    end

    if seq[1] <= search.target <= seq[end]
        return :bisect, seq
    else
        return :discard, seq
    end
end


function BranchAndPrune.bisect(::SequenceSearch, seq)
    mid = div(length(seq), 2)
    return seq[1:mid], seq[mid+1:end]
end

const PRIMES = primes(10000)  # All prime numbers smaller than 10 000

function isinseq(seq, n)
    search = SequenceSearch(seq, n)

    local endtree = nothing
    niter = 0

    for wt in search
        endtree = wt
        niter += 1
    end

    println("Search finished in $niter iterations.")
    return nnodes(endtree) > 0
end

println(isinseq(PRIMES, 18))
println(isinseq(PRIMES, 997))