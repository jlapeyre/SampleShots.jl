# SampleShots

[![Build Status](https://github.com/jlapeyre/SampleShots.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/jlapeyre/SampleShots.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/jlapeyre/SampleShots.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/jlapeyre/SampleShots.jl)


Test various ways to sample from a categorical distribution.
We are intereted in two tasks

* Returning an array of `N` samples from the categorical distribution with `k` categories.
* Returning an array length `k` counting the number of times each category was sampled in `N` samples.


### C++ sampling routines

To test the C++ routines, you have to build the library. On unix, you can run the script [`make_cpp_sampler.sh`](./make_cpp_sampler.sh)

GSL and BLAS must be installed.
