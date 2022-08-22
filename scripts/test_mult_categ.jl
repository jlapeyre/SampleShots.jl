using Revise
using SampleShots
using GSL
using Random

gslrng = GSL.rng_alloc(GSL.gsl_rng_taus)  # gsl_rng_mt19937_1999
jrng = Random.GLOBAL_RNG

for ncat_exp in (1, 2, 3, 4, 5, 6, 7)
    ncats = 10^ncat_exp
    probs = rand_catdist(ncats);
    msamples = zeros(Int, ncats)
    msamples32 = zeros(UInt32, ncats)

    for nsamp_exp in (1, 2, 3, 4, 5, 6)
        nsamp = 10^nsamp_exp
        csamples = zeros(Int, nsamp)

        # @info "cpp ncats = 10^$ncat_exp, nsamp = 10^$nsamp_exp"
        # @btime SampleShots.sample_categorical_cpp!($csamples, $probs);
        # @info "julia gslrng ncats = 10^$ncat_exp, nsamp = 10^$nsamp_exp"
        # @btime SampleShots.categorical!($gslrng, $nsamp, $probs, $csamples);
        # @info "julia jrng ncats = 10^$ncat_exp, nsamp = 10^$nsamp_exp"
        # try
        #     @btime SampleShots.categorical!($jrng, $nsamp, $probs, $csamples);
        # catch
        #     @warn "julia binomial failed..."
        # end
        println()

        @info "julia mult gslrng ncats = 10^$ncat_exp, nsamp = 10^$nsamp_exp"
        @btime SampleShots.multinomial!($gslrng, $nsamp, $probs, $msamples);
        @info "gsl mult gslrng ncats = 10^$ncat_exp, nsamp = 10^$nsamp_exp"
        @btime SampleShots.gsl_multinomial!($gslrng, $nsamp, $probs, $msamples32);
        @info "julia mult jrng ncats = 10^$ncat_exp, nsamp = 10^$nsamp_exp"
        @btime SampleShots.multinomial!($jrng, $nsamp, $probs, $msamples);

        println()
        println()
    end
end

GSL.rng_free(gslrng)

nothing
