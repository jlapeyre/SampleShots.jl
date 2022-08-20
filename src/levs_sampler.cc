// single-threaded
#include <iostream>
#include <random>

#include <gsl/gsl_rng.h>
#include <gsl/gsl_randist.h>
#include <chrono>

// c++ -Wall -O3 -fPIC -lgsl -lcblas -shared -rdynamic -o lev_sample.so lev_sample.cc

extern "C" {
  void sample_categorical(int nstates, int nshot, double *probs, double totalprob, long *samples, unsigned long seed);
  void sample_categorical_rng(int nstates, int nshot, double *probs, double totalprob, long *samples, gsl_rng *gslgen, unsigned long seed);
  long sum_ints(long *x, long n);
}

using namespace std::chrono;

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


int main()
{
    const int nq = 25, nshot = 800000;
    // const int nq=8, nshot=1000;

    int nstates = 1 << nq;
    
    std::default_random_engine generator;
    std::uniform_real_distribution<double> uniform(0.0, 1.0);
    double *probs = new double[nstates], totalprob = 0.0;
    long samples[nshot];

    // Generate (unnormalized) nq-qubit probability distr. Don't include this in timing
    for (int i = 0; i < nstates; i++)
        totalprob += (probs[i] = uniform(generator));

    // std::binomial_distribution<int> binom; Using gsl instead
    gsl_rng *gslgen = gsl_rng_alloc(gsl_rng_taus);

    auto start = high_resolution_clock::now();

    int ntrials = 2;
    unsigned long seed = 1;
    for(int i=0; i < ntrials; i++)
      sample_categorical_rng(nstates, nshot, probs, totalprob, samples, gslgen, seed);

    auto stop = high_resolution_clock::now();

    auto duration = duration_cast<milliseconds>((stop - start) / ntrials);
    std::cout << duration.count() << std::endl;
    return 0;
}
