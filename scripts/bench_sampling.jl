using SampleShots: rand_catdist, multinomial, counts_categorical
using Distributions: AliasTable

function bench_sampling(nqubits::Integer, n_samps::Integer)
    n_cats = 2^nqubits
    probs = rand_catdist(n_cats)
    @time sampler = AliasTable(probs)
    @time counts =counts_categorical(n_samps, sampler)
    return counts
end


function run_a_bench(nqubits=20, n_samps=800_000)
    return bench_sampling(nqubits, n_samps)
end
