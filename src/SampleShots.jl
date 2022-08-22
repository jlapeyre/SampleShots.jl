module SampleShots

using GSL: GSL
using Random: Random
using Distributions: Categorical, Distributions, params, probs, ncategories, support, median
using Distributions: Multinomial, AliasTable, Binomial, BinomialTPESampler
using StatsBase: countmap

export rand_catdist, multinomial, count_samples!
export categorical_cpp!, categorical_cpp_rng!, categorical_cpp

include("compile_cpp.jl")

function __init__()
    ensure_cpp_lib_compiled()
end

function categorical_cpp_rng!(rng::Ptr{GSL.gsl_rng}, samples::Vector{Int64}, probs::Vector{Float64},
                             totalprob::Float64=sum(probs); seed = 1)
    @ccall _SAMPLE_LIB_PATH.sample_categorical_rng(
        length(probs)::Cint, length(samples)::Cint, probs::Ptr{Cdouble}, totalprob::Cdouble,
        samples::Ptr{Clong}, rng::Ptr{Cvoid}, seed::Culong)::Cvoid
    return samples
end

# Allocate an rng in the cpp code
function categorical_cpp!(samples::Vector{Int64}, probs::Vector{Float64},
                             totalprob::Float64=sum(probs); seed = 1)
    @ccall _SAMPLE_LIB_PATH.sample_categorical(
        length(probs)::Cint, length(samples)::Cint, probs::Ptr{Cdouble}, totalprob::Cdouble,
        samples::Ptr{Clong}, seed::Culong)::Cvoid
    return samples
end

categorical_cpp(probs::Vector{Float64}, nshot::Integer, totalprob::Float64=sum(probs); seed = UInt64(1)) =
    categorical_cpp!(Array{Int}(undef, nshot), probs, totalprob; seed=seed)

categorical_cpp_rng(rng::Ptr{GSL.gsl_rng}, probs::Vector{Float64}, nshot::Integer, totalprob::Float64=sum(probs); seed = UInt64(1)) =
    categorical_cpp!(rng, Array{Int}(undef, nshot), probs, totalprob; seed=seed)


###
### Accumulating counts
###

Base.maximum(atab::AliasTable) = ncategories(atab) # Should be defined already, but is not.

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
    count_samples(n_samps::Integer, sampler)

Return a vector of counts accumulated from `n_samps` samples of `sampler`.
This calls `count_samples!`. The call `rand(sampler)` must return valid
indices into a `Vector`.
"""
count_samples(n_samps::Integer, sampler) =
    count_samples!(Array{Int}(undef, maximum(sampler)), n_samps, sampler)

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
    multinomial_julia(n_samps, probs::Vector)

Return a `Multinomial` instance for sampling counts corresponding to `n_samps` samples of
the categorical distribution `probs`.

    multinomial_julia(n_samps, n_cats::Integer)

Construct the `Multinomial` using random probabilities via `rand_catdist`.
"""
multinomial_julia(n_samps, n_cats::Integer) = multinomial(n_samps, rand_catdist(n_cats))
multinomial_julia(n_samps, probs::Vector) = Multinomial(n_samps, probs; check_args=false)

function multinom_rand(nsamp::Integer, p::AbstractVector{Float64})
    rng = Random.default_rng()
    x = Vector{Int}(undef, length(p))
    return Distributions.multinom_rand!(rng, nsamp, p, x)
end

# Passed to multinomial routine to write `val` from multinomial sample `k` times into vector `v`.
function _fill_one_val(v::Vector, val::Integer, k::Integer, sum_n::Integer)
    for i in 1:val
        @inbounds v[sum_n + i] = k
    end
    return v
end

# Passed to multinomial routine to simply record the sample for category `k`.
function _counts_func(v::Vector, val::Integer, k::Integer, sum_n) # sum_n ignored
    @inbounds v[k] = val
end

categorical(nsamp::Integer, probs::AbstractVector) = categorical!(Random.GLOBAL_RNG, nsamp, probs, Vector{Int}(undef, nsamp))
categorical(rng, nsamp::Integer, probs::AbstractVector) = categorical!(rng, nsamp, probs, Vector{Int}(undef, nsamp))

function categorical!(rng, nsamp::Integer, probs::AbstractVector, samples::Vector)
    length(samples) >= nsamp || throw(DimensionMismatch("length(samples) must be at least as large as nsamp"))
    return _multinomial_or_categorical_rng!(rng, nsamp, probs, samples, _fill_one_val)
end

multinomial(nsamp, probs::AbstractVector) = multinomial!(Random.GLOBAL_RNG, nsamp, probs, similar(probs, Int))
multinomial(rng, nsamp, probs::AbstractVector) = multinomial!(rng, nsamp, probs, similar(probs, Int))

function multinomial!(rng, nsamp, probs::AbstractVector, samples::Vector)
    length(probs) == length(samples) || throw(DimensionMismatch("`probs` and `samples` must have the same length"))
    return _multinomial_or_categorical_rng!(rng, nsamp, probs, samples, _counts_func)
end

function _multinomial_or_categorical_rng!(rng::Random.AbstractRNG, args...)
    binomial_func = (rngs, n, p) -> rand(rng, Binomial(n, p))::Int
    return _multinomial_or_categorical!(rng, binomial_func, args...)
end

function _multinomial_or_categorical_rng!(rng::Ptr{GSL.gsl_rng}, args...)
    binomial_func = (rngs, n, p) -> GSL.ran_binomial(rng, p, n)::UInt32
    return _multinomial_or_categorical!(rng, binomial_func, args...)
end

# The main structure is copied from the gsl C function gsl_ran_multinomial.
# The check for p > 0 is added to prevent the Julia Binomial sampler from erroring.
# binomial_func -- Function that samples from the binomial distribution.
# set_val_func -- function that accumulates either 1) samples for categorical, or 2) binned samples for multinomial.
function _multinomial_or_categorical!(rng, binomial_func, nsamp, probs::Vector, samples, set_val_func)
    sum_p = zero(eltype(probs))
    sum_n = 0
    norm = sum(probs)
    @inbounds for k in eachindex(probs)
        p = probs[k] / (norm - sum_p)
        n = nsamp - sum_n
        if p >= 1
            sample = n
        elseif p > 0
            sample = binomial_func(rng, n, p)
        else
            sample = 0
        end
        set_val_func(samples, sample, k, sum_n)
        sum_p += probs[k]
        sum_n += sample
    end
    return samples
end

gsl_multinomial(rng::Ptr{GSL.gsl_rng}, nsamp, probs::AbstractVector) =
    gsl_multinomial!(rng, nsamp, probs, Vector{UInt32}(undef, length(probs)))

function gsl_multinomial!(rng::Ptr{GSL.gsl_rng}, nsamp, probs::AbstractVector, counts::AbstractVector)
    GSL.ran_multinomial(rng, length(probs), nsamp, probs, counts)
    return counts
end


end # module
