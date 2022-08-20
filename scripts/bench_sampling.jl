using SampleShots: rand_catdist, multinomial, count_int_samples, count_samples!
using Distributions: AliasTable

function bench_sampling(nqubits::Integer, n_samps::Integer)
    n_cats = 2^nqubits
    probs = rand_catdist(n_cats)
    t_make_alias_table = @elapsed sampler = AliasTable(probs)
    @show t_make_alias_table
    t_sample_alias_table = @elapsed counts = count_int_samples(n_samps, sampler)
    @show t_sample_alias_table
    return counts
end


function run_a_bench(nqubits=25, n_samps=800_000)
    return bench_sampling(nqubits, n_samps)
end
