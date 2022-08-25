def make_proc_results(results: dict):
    proc_results = results.copy()
    proc_results['ratio'] = compute_ratio(results)
    return proc_results


def print_ratio(proc_results, fn='ratio2.txt'):
    with open(fn, 'w') as fp:
        ratio = proc_results['ratio']
        nprobs = proc_results['num_probs']
        for p, r in zip(nprobs, ratio):
            fp.write(f"{repr(p)} {repr(r)}\n")
        fp.write("\n")


def compute_ratio(results: dict):
    num_probs = results['num_probs']
    num_samps = results['num_samps']
    return [s / p for (p, s) in zip(num_probs, num_samps)]

# It looks like the useful scaling is _exp=1. I thought I
# saw 2 used in another library (maybe Julia?)
def compute_pow_ratio(results: dict, _exp=2):
    num_probs = results['num_probs']
    num_samps = results['num_samps']
    return [s**_exp / p for (p, s) in zip(num_probs, num_samps)]
