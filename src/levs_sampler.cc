// single-threaded
#include <iostream>
#include <random>

#include <gsl/gsl_rng.h>
#include <gsl/gsl_randist.h>

extern "C" {
  void sample_categorical(int nstates, int nshot, double *probs, double totalprob, long *samples, unsigned long seed);
  void sample_categorical_rng(int nstates, int nshot, double *probs, double totalprob, long *samples, gsl_rng *gslgen, unsigned long seed);
  long sum_ints(long *x, long n);
}

void sample_categorical_rng(int nstates, int nshot, double *probs, double totalprob, long *samples, gsl_rng *gslgen, unsigned long seed)
{
  int s, offset = 0, r = nshot;

  gsl_rng_set(gslgen, seed);
  // Take nshot of samples from the above distribution, by conditional-binomial method:
  for (int j = 0; j < nstates - 1; j++)
    {
      // s = binom(generator, std::binomial_distribution<int>::param_type(r, probs[j]/totalprob));
      s = gsl_ran_binomial(gslgen, probs[j] / totalprob, r);
      r -= s;
      for (int k = 0; k < s; k++)
        samples[offset++] = j;
      if (!r)
            break;
      totalprob -= probs[j];
    }
  for (int k = 0; k < r; k++)
    samples[offset++] = nstates - 1;
}

void sample_categorical(int nstates, int nshot, double *probs, double totalprob, long *samples, unsigned long seed)
{
  gsl_rng *gslgen = gsl_rng_alloc(gsl_rng_taus);
  sample_categorical_rng(nstates, nshot, probs, totalprob, samples, gslgen, seed);
  gsl_rng_free(gslgen);
}
