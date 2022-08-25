import sys
import os
import shutil
import subprocess
import pprint
import numpy as np
import timeit
import collections

rng = np.random.default_rng()

CountsA = collections.namedtuple("CountsA", "inds counts")

def get_count(counts, i):
    ind = np.searchsorted(counts.inds, i)
    if counts.inds[ind] == i:
        return counts.counts[ind]
    else:
        return 0


def CountsA_to_dict(counts: CountsA):
    return dict(zip(counts.inds, counts.counts))


def CountsA_to_full_array(counts: CountsA, arrlen):
    full_array = np.zeros(arrlen, dtype='int')
    full_array[counts.inds] = counts.counts
    return full_array


def full_array_to_CountsA(array):
    nzs = np.nonzero(array)[0] # returns a tuple
    return CountsA(nzs, array[nzs])


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


def count_array(array):
    inds, counts = np.unique(array, return_counts=True)
    return CountsA(inds, counts)


def count_map(array):
    "Return a dict whose keys are items from ``array`` and value are the number of times each item occurs."
    inds, counts = np.unique(array, return_counts=True)
    return dict(zip(inds, counts))


def sample_counts(probs, num_samples, rng=rng):
    """Draw ``num_samples`` samples from  categorical distribution ``probs``
    and build a `CountsA` of the results. All naively.
    """
    samples = sample_probs(probs, num_samples, rng=rng)
    return count_array(samples)


def sample_counts_dict(probs, num_samples, rng=rng):
    """Draw ``num_samples`` samples from  categorical distribution ``probs``
    and build a count map of the results. All naively.
    """
    counts = sample_counts(probs, num_samples, rng=rng)
    return dict(zip(counts.inds, counts.counts))


def sample_counts_mult(probs, num_samples, rng=rng):
    """Effectively draw ``num_samples`` samples from  categorical distribution ``probs``
    and count the number of each result. This isn not done naively, but rather from sampling
    once from the associated multinomial distribution.

    Returns a numpy array. Indices are categories, values are counts.
    """
    count_samples = rng.multinomial(num_samples, probs)
    return count_samples


def sample_counts_mult_CountsA(probs, num_samples, rng=rng):
    """Effectively draw ``num_samples`` samples from  categorical distribution ``probs``
    and count the number of each result. This isn not done naively, but rather from sampling
    once from the associated multinomial distribution.

    Returns a CountsA
    """
    count_samples = rng.multinomial(num_samples, probs)
    return full_array_to_CountsA(count_samples)


def sample_counts_mult_dict(probs, num_samples, rng=rng):
    """Same as ``sample_counts_mult`` except the numpy array of counts is converted to a dict, which is returned.
    Categories (indices) with value zero are *not* omitted.
    """
    counts = sample_counts_mult_CountsA(probs, num_samples, rng=rng)
    return dict(zip(counts.inds, counts.counts))


###
### Benchmarking methods
###


def time_code(num_timeit_times=1000, num_probs=10, num_samples=1000, num_reps=3, count_func="sample_counts"):
    imports = "make_probs, sample_counts, sample_counts_mult, sample_counts_mult_dict, sample_counts_dict, sample_counts_mult_CountsA"
    setup_code = f"from __main__ import {imports} ; probs=make_probs({num_probs})"
    return timeit.Timer(f"{count_func}(probs, {num_samples})",
                        setup=setup_code).repeat(num_reps, num_timeit_times) #  timeit(num_timeit_times)


from math import log

crossover_params = [
    (10, 1000),
    (12, 1000),
    (20, 1000),
    (30, 1000),
    (40, 1000),
    (50, 1000),
    (60, 1000),
    (70, 1000),
    (100, 1000),
    (200, 1000),
    (400, 1000),
    (600, 1000),
    (800, 1000),
    (10**3, 1000),
    (1100, 1000),
    (1200, 1000),
    (1300, 1000),
    (1400, 1000),
    (1500, 1000),
    (1600, 1000),
    (1700, 1000),
    (1800, 1000),
    (1900, 1000),
    (2*10**3, 1500),
    (3*10**3, 1500),
    (4*10**3, 1500),
    (5*10**3, 800),
    (8*10**3, 500),
    (10**4, 200),
    (2 * 10**4, 100),
    (3 * 10**4, 100),
    (4 * 10**4, 50),
    (5 * 10**4, 50),
    (6 * 10**4, 50),
    (7 * 10**4, 50),
    (8 * 10**4, 50),
    (9 * 10**4, 30),
    (10**5, 30),
    (2 * 10**5, 30),
    (3 * 10**5, 30),
    (5 * 10**5, 30),
    (8 * 10**5, 20),
    (10**6, 10),
    (10**6 + 2 * 10**5, 10),
    (10**6 + 5 * 10**5, 10),
    (10**6 + 7 * 10**5, 10),
    (2 * 10**6, 5),
    (3 * 10**6, 5),
    (5 * 10**6, 5),
    (8 * 10**6, 1, 0.1),
    (9 * 10**6, 1, 0.1),
    (10**7, 1, 0.1),
    (2 * 10**7, 1, 0.1),
    (4 * 10**7, 1, 0.05),
    (7 * 10**7, 1, 0.05),
    (9 * 10**7, 1, 0.045),
]

import pprint

def write_res(samp_results: dict, basefn: str):
    fname = basefn + ".txt"
    if os.path.exists(fname):
        shutil.copyfile(fname, basefn +  ".bak.txt")
    with open(fname, 'w') as fp:
        fp.write(pprint.pformat(samp_results))


def run_crossovers(params=crossover_params, mult_func="sample_counts_mult", outfile="sample_data",
                   timeit_factor=1,
                   choice_func="sample_counts", verbose=True):
    num_probs_save = []
    num_samples_save = []
    num_samples_save = []
    start_frac_save = []
    num_timeit_times_save = []
    choice_time_save =[]
    mult_time_save =[]
    num_reps_save = []
    ratio_save = []

    spresponse = subprocess.run(["git",  "log", "--pretty=format:'%h'", "-n", "1" ], capture_output=True)
    commit = spresponse.stdout.decode()
    for ps in params:
        start_frac = 1.0
        if len(ps) == 3:
            (num_probs, num_timeit_times, start_frac) = ps
        else:
            (num_probs, num_timeit_times) = ps
        start_frac_save.append(start_frac)
        print(f"num_probs = {num_probs}", end="")
        num_timeit_times = num_timeit_times * timeit_factor
        sys.stdout.flush()
        if verbose:
            print()
        else:
            print(" ", end="")
        (num_samples, choice_time, mult_time, num_reps) = find_crossover(
            num_probs, num_timeit_times, start_frac=start_frac,
            mult_func=mult_func, choice_func=choice_func, verbose=verbose
        )
        print()
        num_probs_save.append(num_probs)
        num_samples_save.append(num_samples)
        num_timeit_times_save.append(num_timeit_times)
        choice_time_save.append(choice_time)
        mult_time_save.append(mult_time)
        num_reps_save.append(num_reps)
        ratio_save.append(num_samples / num_probs) # this is post processing, but whatever
        result_dict = {'num_probs': num_probs_save,
                       'num_samps': num_samples_save,
                       'num_timeit': num_timeit_times_save,
                       'start_frac': start_frac_save,
                       'choice_time': choice_time_save,
                       'mult_time': mult_time_save,
                       'mult_func': mult_func,
                       'choice_func': choice_func,
                       'num_reps': num_reps_save,
                       'ratio': ratio_save,
                       'timeit_factor': timeit_factor,
                       'commit': commit
                       }
        write_res(result_dict, outfile)
    return result_dict

# def time_ratio(choice_time, mult_time):
#     if mult_time > choice_time:
#         ratio = (mult_time - choice_time) / mult_time
#     else:
#         ratio = (choice_time - mult_time) / choice_time
#     return ratio

# start_frac = 0.15 is always high enough if we don't convert to dict
def find_crossover(num_probs, num_timeit_times=200, start_frac=1.0, mult_func="sample_counts_mult", choice_func="sample_counts", verbose=True):
    num_samples_hi = round(start_frac * num_probs)
    num_samples_lo = 1
    choice_time = 0.0
    mult_time = 0.0
    num_reps = 2
    for i in range(100):
        num_samples = int((num_samples_hi + num_samples_lo) / 2)
        # divide by correct number, not num_reps
        choice_time = min(time_code(num_timeit_times, num_probs, num_samples, count_func=choice_func, num_reps=num_reps)) / num_timeit_times
        mult_time = min(time_code(num_timeit_times, num_probs, num_samples, count_func=mult_func, num_reps=num_reps)) / num_timeit_times
        time_diff = mult_time - choice_time
        if verbose:
            print(f"t_rat: {time_diff/max([choice_time,mult_time])}, lo: {num_samples_lo}, hi: {num_samples_hi}, nsamps: {num_samples}")
        else:
            print(".", end="")
            sys.stdout.flush()
        if time_diff > 0:
            mult_worse = True
        else:
            mult_worse = False
        if mult_worse:
            num_samples_lo = num_samples
        else:
            num_samples_hi = num_samples
        samp_diff = num_samples_hi - num_samples_lo
        if samp_diff < 1 or samp_diff / num_samples_hi < 0.00001:
            break
    print()
    ratio = num_samples / num_probs
    print(f"ratio: {ratio}, num_samps: {num_samples}")
    return (num_samples, choice_time, mult_time, num_reps)


###
### run_timings works with `some_params` below
###

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
