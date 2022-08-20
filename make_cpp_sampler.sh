#!/bin/sh

c++ -Wall -O3 -fPIC -lgsl -lcblas -shared -rdynamic -o ./lib/levs_sampler.so ./src/levs_sampler.cc
