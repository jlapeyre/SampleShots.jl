### Sampling problem

We want to collect $n$ samples from the probability distribution $p(i), i=1,\ldots k$ and
return the number of times that each value of $i$ was sampled. This corresponds to binning
shots (with the finest bins).

There are at least two ways to do this sampling. We can either perform the procedure just described,
or alternatively, sample once from the associated multinomial distribution. Both give counts with
the same statistics.  The question is when should we prefer one over the other? Let's give them
names

* The *categorical* method. The first method above. (The first step is sampling from the
  categorical distribution $\mathbf{p}=(p_1,\ldots,p_k)$.)
* The *multinomial* method. The second method above. Draw a single sample from a multinomial distribution.

#### Motivation

Qiskit provides this sampling in various places. For example `quantum_info` and in `qiskit-aer`. Making
it efficient is useful, especially if we can reduce the time complexity. Sampling in some regimes can be
quick rather than strictly impossible if we use the right method.

#### Time complexity
* Both methods are at least linear in $k$, i.e. $O(k)$ in $k$. I guess all reasonable programming language
  implementations are really $O(k)$.
* The multinomial method is $O(1)$ in $n$. The categorical method is $O(n)$. So for large enough $n$,
  multinomial is better.
* In practice there are complicating factors: pre- and post-processing, data structures, PL constraints, whether you want to
  do sampling repeatedly. There are different sub-algorithms that can be chosen for each of the two methods.

### Data structures

* Limitations of numpy
* ??
