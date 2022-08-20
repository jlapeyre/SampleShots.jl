// single-threaded
#include <iostream>
#include <random>

#include <gsl/gsl_rng.h>
#include <gsl/gsl_randist.h>
#include <chrono>

// c++ -O3 -lblas -lgsl -o lev_sample lev_sample.cc
// c++ -Wall -O3 -fPIC -lgsl -lcblas -shared -rdynamic -o lev_sample.so lev_sample.cc

extern "C" {
  void take_samples_rng(int nstates, int nshot, double *probs, double totalprob, long *samples);
  void take_samples(int nstates, int nshot, double *probs, double totalprob, long *samples, gsl_rng *gslgen);
  long sum_ints(long *x, long n);
}



using namespace std::chrono;


void take_samples(int nstates, int nshot, double *probs, double totalprob, long *samples, gsl_rng *gslgen)
{
  int s, offset = 0, r = nshot;

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


void take_samples_rng(int nstates, int nshot, double *probs, double totalprob, long *samples)
{
  gsl_rng *gslgen = gsl_rng_alloc(gsl_rng_taus);
  take_samples(nstates, nshot, probs, totalprob, samples, gslgen);
  gsl_rng_free(gslgen);
}


long sum_ints(long *x, long n) {
  long _sum = 0;
  for(int i=0; i < n; i++)
    _sum += x[i];
  return _sum;
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

    std::binomial_distribution<int> binom;
    gsl_rng *gslgen = gsl_rng_alloc(gsl_rng_taus);

    auto start = high_resolution_clock::now();

    int ntrials = 2;
    for(int i=0; i < ntrials; i++)
      take_samples(nstates, nshot, probs, totalprob, samples, gslgen);

    auto stop = high_resolution_clock::now();

    auto duration = duration_cast<milliseconds>((stop - start) / ntrials);
    std::cout << duration.count() << std::endl;
    return 0;
}

