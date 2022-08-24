module GSLX

using GSL: GSL
#using GSL_jll: GSL_jll


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
        finalizer(x -> GSL.rng_free(rng.x), mrng)
        return rng
    end
end

(rng::RNG)() = rng.x


mutable struct _MUTRNG
    x::Ptr{GSL.gsl_rng}
end

struct RNGA
    x::Ptr{GSL.gsl_rng}
    _y::_MUTRNG
    function RNGA(rng_type=GSL.gsl_rng_taus2)
        _rng = GSL.rng_alloc(rng_type)
        mrng = _MUTRNG(_rng)
        rng = new(_rng, mrng)
        finalizer(x -> GSL.rng_free(rng.x), mrng)
        return rng
    end
end

(rng::RNGA)() = rng.x


struct RNG2
    x::Ref{Ptr{GSL.gsl_rng}}
    function RNG2(rng_type=GSL.gsl_rng_taus2)
        rng = new(Ref(GSL.rng_alloc(rng_type)))
        finalizer(x -> GSL.rng_free(x[]), rng.x)
        return rng
    end
end

(rng::RNG2)() = rng.x[]

# function rng_alloc(T)
#     res = ccall((:gsl_rng_alloc, GSL_jll.libgsl), Ptr{GSL.gsl_rng}, (Ptr{GSL.gsl_rng_type},), T)
#     return Ref(unsafe_load(res))
# end

mutable struct RNG3
    x::Ptr{GSL.gsl_rng}
    function RNG3(rng_type=GSL.gsl_rng_taus2)
        _rng::Ptr{GSL.gsl_rng} = GSL.rng_alloc(rng_type)::Ptr{GSL.gsl_rng}
#        mrng = _MUTRNG(_rng)
        rng = new(_rng)
        finalizer(x -> GSL.rng_free(rng.x), rng)
        return rng
    end
end

(rng::RNG3)()::Ptr{GSL.gsl_rng} = rng.x::Ptr{GSL.gsl_rng}


function ran_multinomial!(rng::Ptr{GSL.gsl_rng}, nsamp::Integer, probs::AbstractVector, counts::AbstractVector)
    GSL.ran_multinomial(rng, length(probs), nsamp, probs, counts)
    return counts
end

# """
#     new_rng(rng_type = GSL.gsl_rng_taus2)

# Allocate and return a gsl rng. The storage wil be freed by Julia's garbage collector.
# Do not call `GSL.rng_free` on the returned rng. If you do, Julia will exit with a double free error.
# """
# function new_rng(rng_type = GSL.gsl_rng_taus2)
#     gslrng = GSL.rng_alloc(rng_type)
#     unloaded_rng = unsafe_load(gslrng)
#     finalizer(x -> GSL.rng_free(gslrng), unloaded_rng) # (println("freeing rng"), GSL.rng_free(gslrng))
#     return unloaded_rng
# end


end
