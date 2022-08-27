# SampleShots

[![Build Status](https://github.com/jlapeyre/SampleShots.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/jlapeyre/SampleShots.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/jlapeyre/SampleShots.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/jlapeyre/SampleShots.jl)

Test various ways to sample from a categorical distribution.
We are intereted in two tasks

* Returning an array of `N` samples from the categorical distribution with `k` categories.
* Returning an array length `k` counting the number of times each category was sampled in `N` samples.


### C++ sampling routines

Some tests use C++ code.

The code in [./src/compile_cpp.jl](./src/compile_cpp.jl) compiles the c++ code automatically. But the flags have
not been tested on windows.

<!-- #### Dependencies -->

<!-- In [`Project.toml`](./Project.toml) there are two gsl dependencies -->
<!-- * `GSL.jl` for Julia wrappers -->
<!-- * `GSL_jll.jl` for the shared libraries and headers. We need this for compiling C++ code -->
