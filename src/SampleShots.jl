module SampleShots

using Distributions: Categorical, Distributions, params, probs, ncategories, support, median
using Distributions: Multinomial, AliasTable
using StatsBase: countmap

export rand_catdist, multinomial, count_int_samples, count_samples!

const _toplevel_path = dirname(dirname(pathof(SampleShots)))
const sample_lib_path = joinpath(_toplevel_path, "lib", "levs_sampler.so")

function __init__()
    isfile(sample_lib_path) || @warn """
    $sample_lib_path not found.
    See the README.md for information on how to compile it.
    """
end

###
### Using C++ routine
###

function sample_categorical(probs::Vector{Float64}, nshot::Integer, totalprob::Float64=sum(probs); seed = UInt64(1))
    nstates = length(probs)
    samples = Array{Int}(undef, nshot)
#    totalprob = sum(probs)
    @ccall sample_lib_path.sample_categorical(
        nstates::Cint, nshot::Cint, probs::Ptr{Cdouble}, totalprob::Cdouble, samples::Ptr{Clong}, seed::Culong
    )::Cvoid
    return samples
end


###
### Accumulating counts
###


"""
    accumulate_counts!(func, counts, n_samps::Integer)

Make `n_samps` calls to `func`, accumulating counts of results in container `counts`.
`func` must return a valid index or key into `counts`.
"""
function accumulate_counts!(func, counts, n_samps::Integer)
    for _ in 1:n_samps
        counts[func()] += 1
    end
    return counts
end

max_sample_value(atab::AliasTable) = ncategories(atab)

"""
    count_samples!(counts::Vector, n_samps::Integer, sampler)

Collect `n_samps` from `sampler` and accumulate counts into `counts`.
A call `rand(sampler)`, which must return a valid index into `counts`
will be made for each sample.
"""
function count_samples!(counts::Vector, n_samps::Integer, sampler)
    fill!(counts, zero(eltype(counts)))
    return accumulate_counts!(() -> rand(sampler), counts, n_samps)
end

"""
    count_int_samples(n_samps::Integer, sampler)

Return a vector of counts accumulated from `n_samps` samples of `sampler`.
This calls `count_samples!`. The call `rand(sampler)` must return valid
indices into a `Vector`.
"""
count_int_samples(n_samps::Integer, sampler) =
    count_samples!(Array{Int}(undef, max_sample_value(sampler)), n_samps, sampler)

###
### Making distributions
###

"""
    rand_catdist(n_cats)::Vector{Float64}

Return a `Vector` representing a categorical probability distribution with random entries.

The probabilities are first sampled from the uniform distribution on (0,1), then are normalized.
"""
function rand_catdist(n_cats)::Vector{Float64}
    probs = rand(n_cats)
    probs .= probs ./ sum(probs)
end

"""
    multinomial(n_samps, probs::Vector)

Return a `Multinomial` instance for sampling counts corresponding to `n_samps` samples of
the categorical distribution `probs`.

    multinomial(n_samps, n_cats::Integer)

Construct the `Multinomial` using random probabilities via `rand_catdist`.
"""
multinomial(n_samps, n_cats::Integer) = multinomial(n_samps, rand_catdist(n_cats))
multinomial(n_samps, probs::Vector) = Multinomial(n_samps, probs; check_args=false)

"""
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

# """
#     counts_categorical!(counts::Vector, n_samps::Integer, cat_dist_sampler::AliasTable)

# Collect `n_samps` from `cat_dist_sampler` and accumulate counts into `counts`.
# """
# function counts_categorical!(counts::Vector, n_samps::Integer, cat_dist_sampler::AliasTable)
#     fill!(counts, zero(eltype(counts)))
#     return accumulate_counts!(() -> rand(cat_dist_sampler), counts, n_samps)
# end

# """
#     counts_categorical(n_samps::Integer, cat_dist_sampler::AliasTable)

# Return a vector of counts accumulated from `n_samps` samples of `cat_dist_sampler`.
# This calls `counts_categorical!`.
# """
# counts_categorical(n_samps::Integer, cat_dist_sampler::AliasTable) =
#     counts_categorical!(Array{Int}(undef, ncategories(cat_dist_sampler)), n_samps, cat_dist_sampler)


end # module
