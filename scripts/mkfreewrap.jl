using Revise
using GSL
# using SampleShots
#using SampleShots.GSLX: GSLX

struct AllocFree{T, AF, FF}
    x::Ptr{T}
    _y::Ref
    function AllocFree{T,AF,FF}(args...) where {T, AF, FF}
        _obj = AF.instance(args...)
        mobj = Ref(_obj)
        obj = new{T,AF,FF}(_obj, mobj)
        finalizer(x -> FF.instance(obj.x), mobj)
        return obj
    end
end

(obj::AllocFree)() = obj.x

mkrng(t=GSL.gsl_rng_taus2) = AllocFree{GSL.gsl_rng, typeof(GSL.rng_alloc), typeof(GSL.rng_free)}(t)
