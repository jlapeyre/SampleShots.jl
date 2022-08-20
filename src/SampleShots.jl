module SampleShots

using Distributions: Categorical, Distributions, params, probs, ncategories, support, median
using Distributions: Multinomial, AliasTable
using StatsBase: countmap

"""
    rand_catdist(n_cat)::Vector{Float64}

Return a `Vector` representing a categorical probability distribution with random entries.

The probabilities are first sampled from the uniform distribution on (0,1), then are normalized.
"""
function rand_catdist(n_cat)::Vector{Float64}
    probs = rand(n_cat)
    probs .= probs ./ sum(probs)
end

"""
    multinomial(n_samps, probs::Vector)

Return a `Multinomial` instance for sampling counts corresponding to `n_samps` samples of
the categorical distribution `probs`.

    multinomial(n_samps, n_cat::Integer)

Construct the `Multinoial` using random probabilities via `rand_catdist`.
"""
multinomial(n_samps, n_cat::Integer) = multinomial(n_samps, rand_catdist(n_cat))
multinomial(n_samps, probs::Vector) = Multinomial(n_samps, probs; check_args=false)

"""
    multinomial(n_samps, probs::Vector)

"""
    counts_categorical(n_samps, Categorical(_probs; check_args=false))

counts_categorical(n_samps::Integer, cat_dist::Categorical) =
    counts_categorical!(Array{Int}(undef, ncategories(cat_dist)), n_samps, cat_dist)



    my_multinomial(n_samps, probs)

Sample from the distribution of counts obtained by drawing `n_samps` samples from discrete
distribution `probs`.
"""
function my_multinomial(n_samps, probs)
    sum(probs) ≈ 1 || error("probs is not a normalized probability distribution")
    Nrem = n_samps   # N - Nrem are the samples collected so far.
    counts = Array{Int}(undef, length(probs)) # samples of counts.
    q = one(eltype(probs)) # unnormalized probability of remaining i
    for p in @view probs[begin:end-1] # firstindex(probs):(lastindex(probs) - 1)
        nsamp = rand(Binomial(Nrem, p / q))
        push!(counts, nsamp)
        Nrem -= nsamp
        q -= p
    end
    push!(counts, Nrem) # All the remaining go with last i with prob 1.
    return counts
end


end # module
