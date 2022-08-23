module GSLX

using GSL: GSL

"""
    new_rng(rng_type = GSL.gsl_rng_taus2)

Allocate and return a gsl rng. The storage wil be freed by Julia's garbage collector.
Do not call `GSL.rng_free` on the returned rng. If you do, Julia will exit with a double free error.
"""
function new_rng(rng_type = GSL.gsl_rng_taus2)
    gslrng = GSL.rng_alloc(rng_type)
    finalizer(x -> GSL.rng_free(gslrng), unsafe_load(gslrng)) # (println("freeing rng"), GSL.rng_free(gslrng))
    return gslrng
end


function ran_multinomial!(rng::Ptr{GSL.gsl_rng}, nsamp::Integer, probs::AbstractVector, counts::AbstractVector)
    GSL.ran_multinomial(rng, length(probs), nsamp, probs, counts)
    return counts
end

end
