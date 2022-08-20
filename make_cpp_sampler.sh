#!/bin/sh

# Build using gsl managed by Julia. But, this is not portable.
# Code in ./src/compile_cpp.jl is more robust
c++ -Wall -march=native -O3 -fPIC -L/home/lapeyre/.julia/artifacts/d159acf1739aafc829461d61aad66f5d718ce036/lib -lgsl -lgslcblas -shared -rdynamic -o ./lib/levs_sampler.so ./src/levs_sampler.cc -I/home/lapeyre/.julia/artifacts/d159acf1739aafc829461d61aad66f5d718ce036/include/gsl, -Wl,-rpath=/home/lapeyre/.julia/artifacts/d159acf1739aafc829461d61aad66f5d718ce036/lib

# Build from system installed gsl and blas (except gsl may use its own copy of blas ?)
# c++ -Wall -O3 -fPIC -lgsl -lcblas -shared -rdynamic -o ./lib/levs_sampler.so ./src/levs_sampler.cc
