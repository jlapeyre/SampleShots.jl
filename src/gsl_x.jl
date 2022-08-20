module GSLX
using GSL: GSL

"""
    GSLX.RNG(rng_type=GSL.gsl_rng_taus2)

Return a new rng. It is not safe or necessary to directly access or change the fields of
this struct. The returned rng is a callable object. Calling it returns a pointer to the
low-level GSL rng that must be passed to low-level GSL routines expecting an rng.
"""
struct RNG
    x::Ptr{GSL.gsl_rng}
    _y::Ref
    function RNG(rng_type=GSL.gsl_rng_taus2)
        _rng = GSL.rng_alloc(rng_type)
        mrng = Ref(_rng)
        rng = new(_rng, mrng)
        finalizer(r -> GSL.rng_free(r.x), mrng)
        return rng
    end
end

(rng::RNG)() = rng.x

function ran_multinomial!(rng::Ptr{GSL.gsl_rng}, nsamp::Integer, probs::AbstractVector, counts::AbstractVector)
    GSL.ran_multinomial(rng, length(probs), nsamp, probs, counts)
    return counts
end

end
