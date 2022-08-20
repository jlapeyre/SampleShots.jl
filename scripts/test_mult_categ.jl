using Revise
using SampleShots
using GSL
using Random
using SampleShots.GSLX: GSLX


const gslrng2 = GSLX.RNGA() # new_rng(GSL.gsl_rng_taus)  # gsl_rng_mt19937_1999
const gslrng1= GSLX.RNG() # new_rng(GSL.gsl_rng_taus)  # gsl_rng_mt19937_1999
#const jrng = Random.GLOBAL_RNG

function timediffs1(n)
    c2 = 0
    N = 10
    for i in 1:N
        t1 = 0.0
        t2 = 0.0
        t1 += @elapsed sumlots1(n)
        t2 += @elapsed sumlots2(n)
        t1 += @elapsed sumlots1(n)
        t2 += @elapsed sumlots2(n)
        t1 += @elapsed sumlots1(n)
        t2 += @elapsed sumlots2(n)
        t1 += @elapsed sumlots1(n)
        t2 += @elapsed sumlots2(n)
        @show ((t2-t1)/t2)
        if t2 < t1
            c2 += 1
        end
    end
    @info "$c2 / $N"
end

function timediffs2(n)
    c2 = 0
    N = 10
    for i in 1:N
        t1 = 0.0
        t2 = 0.0
        t1 += @elapsed sumlots3(n)
        t2 += @elapsed sumlots4(n)
        t1 += @elapsed sumlots3(n)
        t2 += @elapsed sumlots4(n)
        t1 += @elapsed sumlots3(n)
        t2 += @elapsed sumlots4(n)
        t1 += @elapsed sumlots3(n)
        t2 += @elapsed sumlots4(n)
        @show ((t2-t1)/t2)
        if t2 < t1
            c2 += 1
        end
    end
    @info "$c2 / $N"
end


function sumlots1(n)
    _sum = 0.0
    for _ in 1:n
        _sum += GSL.ran_flat(gslrng1(), 0.0, 1.0)
    end
    return _sum
end

function sumlots2(n)
    _sum = 0.0
    xx_rng = gslrng1()
    for _ in 1:n
        _sum += GSL.ran_flat(xx_rng, 0.0, 1.0)
    end
    return _sum
end


function sumlots3(n)
    _sum = 0.0
    for _ in 1:n
        _sum += GSL.ran_flat(gslrng2(), 0.0, 1.0)
    end
    return _sum
end

function sumlots4(n)
    _sum = 0.0
    xx_rng = gslrng2()
    for _ in 1:n
        _sum += GSL.ran_flat(xx_rng, 0.0, 1.0)
    end
    return _sum
end


# function sumlots3(n)
#     _sum = 0.0
#     for _ in 1:n
#         _sum += GSL.ran_flat(gslrng.x, 0.0, 1.0)
#     end
#     return _sum
# end

# function sumlots4(n)
#     _sum = 0.0
#     for _ in 1:n
#         _sum += GSL.ran_flat(first(gslrngpair), 0.0, 1.0)
#     end
#     return _sum
# end

# function sumlots4a(n)
#     _sum = 0.0
#     for _ in 1:n
#         _sum += GSL.ran_flat(gslrngpair[1], 0.0, 1.0)
#     end
#     return _sum
# end


# function sumlots5(n)
#     _sum = 0.0
#     rng = gslrngpair[1]
#     for _ in 1:n
#         _sum += GSL.ran_flat(rng, 0.0, 1.0)
#     end
#     return _sum
# end



function run_multinomials(ncat_exp, nsamp_exp) #probs, msamples, msamples32, ncat_exp=Int(log10(length(probs))), nsamp_exp=Int(log10(nsamp)))
    ncats = 10^ncat_exp
    probs = rand_catdist(ncats);
    msamples = zeros(Int, ncats)
    msamples32 = zeros(UInt32, ncats)
    nsamp = 10^nsamp_exp
    csamples = zeros(Int, nsamp)

    @info "julia mult gslrng ncats = 10^$ncat_exp, nsamp = 10^$nsamp_exp"
    @btime SampleShots.multinomial!($(gslrng()), $nsamp, $probs, $msamples);
    @info "gsl mult gslrng ncats = 10^$ncat_exp, nsamp = 10^$nsamp_exp"
    @btime GSLX.ran_multinomial!($(gslrng()), $nsamp, $probs, $msamples32);
    @info "julia mult jrng ncats = 10^$ncat_exp, nsamp = 10^$nsamp_exp"
    @btime SampleShots.multinomial!($jrng, $nsamp, $probs, $msamples);
    return nothing
end

# for ncat_exp in (1, 2, 3, 4, 5, 6, 7)
#     ncats = 10^ncat_exp
#     probs = rand_catdist(ncats);
#     msamples = zeros(Int, ncats)
#     msamples32 = zeros(UInt32, ncats)

#     for nsamp_exp in (1, 2, 3, 4, 5, 6)
#         nsamp = 10^nsamp_exp
#         csamples = zeros(Int, nsamp)

#         # @info "cpp ncats = 10^$ncat_exp, nsamp = 10^$nsamp_exp"
#         # @btime SampleShots.sample_categorical_cpp!($csamples, $probs);
#         # @info "julia gslrng ncats = 10^$ncat_exp, nsamp = 10^$nsamp_exp"
#         # @btime SampleShots.categorical!($gslrng, $nsamp, $probs, $csamples);
#         # @info "julia jrng ncats = 10^$ncat_exp, nsamp = 10^$nsamp_exp"
#         # try
#         #     @btime SampleShots.categorical!($jrng, $nsamp, $probs, $csamples);
#         # catch
#         #     @warn "julia binomial failed..."
#         # end
#         println()

#         run_multinomials(nsamp, probs, msamples, msamples32)
#         # @info "julia mult gslrng ncats = 10^$ncat_exp, nsamp = 10^$nsamp_exp"
#         # @btime SampleShots.multinomial!($gslrng, $nsamp, $probs, $msamples);
#         # @info "gsl mult gslrng ncats = 10^$ncat_exp, nsamp = 10^$nsamp_exp"
#         # @btime SampleShots.gsl_multinomial!($gslrng, $nsamp, $probs, $msamples32);
#         # @info "julia mult jrng ncats = 10^$ncat_exp, nsamp = 10^$nsamp_exp"
#         # @btime SampleShots.multinomial!($jrng, $nsamp, $probs, $msamples);

#         println()
#         println()
#     end
# end

nothing
