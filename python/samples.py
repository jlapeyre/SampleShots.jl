import numpy as np
import timeit

rng = np.random.default_rng()

# "Naively" here means that a sampling operation does just what it says, rather than
# Using a different technique to get the same statistics.
# For example to count the number of heads in 100 coin flips:
# 1) You can sample from a Bernoulli distribution 100 times and count results
# 2) Sample once from the associated binomial distribution.
# Number 1) is "naive". Number 2) is not.

# Important question: to what extent does this model typical distributions.
# Sometimes, especially in ideal circuit simulations, probabilty is concentrated
# on a small set of states.
def make_probs(num_probs, rng=rng):
    """Make a categorical probability distribution from ``num_probs`` samples
    of the uniform distribution on ``(0, 1)``.
    """
    a = rng.uniform(size=num_probs)
    a /= np.sum(a)
    return a


def sample_probs(probs, num_samples, rng=rng):
    "Return an array of samples of the categorical distribution ``probs``, sampled naively."
    return rng.choice(len(probs), size=num_samples, replace=True, p=probs, shuffle=True)


def count_map(array):
    "Return a dict whose keys are items from ``array`` and value are the number of times each item occurs."
    inds, counts = np.unique(array, return_counts=True)
    return dict(zip(inds, counts))


def sample_counts(probs, num_samples):
    "Sample from categorical distribution ``probs`` and build a count map of the results. All naively"
    samples = sample_probs(probs, num_samples)
    return count_map(samples)

def sample_counts_mult(probs, num_samples):
    count_samples = rng.multinomial(num_samples, probs)
    return count_samples

def sample_counts_mult_dict(probs, num_samples):
    count_samples = rng.multinomial(num_samples, probs)
    return dict(zip(np.arange(len(count_samples)), count_samples))

def time_code(num_timeit_times=1000, num_probs=10, num_samples=1000, num_reps=3, count_func="sample_counts"):
    setup_code = f"from __main__ import make_probs, sample_counts, sample_counts_mult, sample_counts_mult_dict; probs=make_probs({num_probs})"
    return timeit.Timer(f"{count_func}(probs, {num_samples})",
                        setup=setup_code).repeat(num_reps, num_timeit_times) #  timeit(num_timeit_times)

from math import log

# start_frac = 0.15 is always high enough if we don't convert to dict
def find_crossover(num_probs, num_timeit_times=200, start_frac=0.8, to_dict=False):
    num_samps_hi = round(start_frac * num_probs)
    num_samps_lo = 1
    for i in range(100):
        num_samples = int((num_samps_hi + num_samps_lo) / 2)
        count_func = "sample_counts"
        choice_time = min(time_code(num_timeit_times, num_probs, num_samples, count_func=count_func))
        if to_dict:
            count_func = "sample_counts_mult_dict"
        else:
            count_func = "sample_counts_mult"
        mult_time = min(time_code(num_timeit_times, num_probs, num_samples, count_func=count_func))
        time_diff = mult_time - choice_time
        print(f"t_rat: {time_diff/max([choice_time,mult_time])}, lo: {num_samps_lo}, hi: {num_samps_hi}, nsamps: {num_samples}")
        if time_diff > 0:
            mult_worse = True
        else:
            mult_worse = False
        if mult_worse:
            num_samps_lo = num_samples
        else:
            num_samps_hi = num_samples
        samp_diff = num_samps_hi - num_samps_lo
        if samp_diff < 2 or samp_diff / num_samps_hi < 0.05:
            break
    print()
    ratio = num_samples / num_probs
    print(f"ratio: {ratio}, num_samps: {num_samples}")


def run_timings(params):
    reslist = [0, 0]
    for (num_probs, num_samples, num_timeit_times) in params:
        nprob_exp = round(log(num_probs) / log(10))
        nsamp_exp = round(log(num_samples) / log(10))
        for (count_func, label) in (("sample_counts", "choice"), ("sample_counts_mult", "multin")):
            if label == "choice":
                stype = 0
            else:
                stype = 1
            results = time_code(num_timeit_times, num_probs, num_samples, count_func=count_func)
            ndigits = 8
            fac = 10**ndigits
            results = [int(fac * (x/num_timeit_times)) / fac for x in results]
            reslist[stype] = results
#            print(f"{label}: nprobs={num_probs}, nsamp={num_samples}: {results}")
            print(f"{label}: nprobs=10^{nprob_exp}, nsamp=10^{nsamp_exp}: {results}")
            if stype == 1:
                print("mult worse: ", [reslist[1][i] > reslist[0][i]  for i in range(len(results))])
        print()


some_params = [
    (10**3, 10**1, 1000),
    (10**3, 10**2, 1000),
    (10**3, 10**3, 1000),
    (10**4, 10**1, 1000),
    (10**4, 10**2, 100),
    (10**4, 10**3, 100),
    (10**4, 10**4, 100),
    (10**5, 10**2, 10),
    (10**5, 10**3, 10),
    (10**5, 10**4, 10),
    (10**5, 10**5, 5),
    (10**7, 10**5, 3),
    (10**7, 10**6, 3),
    (10**7, 10**7, 3),
    (10**6, 10**3, 3),
    (10**6, 10**4, 3),
    (10**6, 10**5, 3),
    (10**6, 10**6, 3),
    (1000, 10, 1000),
    (100, 10, 5000),
    (10, 1000, 5000),
    (10, 100, 5000)
]
