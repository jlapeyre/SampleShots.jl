PR #8547 wants to change the method for sampling in `quantum_info`. But the original method is sometimes better. So the PR has to be modified. I opened this issue to determine and document when one or the other method is better. At the bottom of this comment is a plot that may have the answer.  (See also #8535, although the present issue largely supersedes that one.)

### Sampling problem

We want to collect $n$ samples from the probability distribution $p(i), i=1,\ldots k$ and return the number of times that each value of $i$ was sampled. This corresponds to binning shots (with the finest bins).

There are at least two ways to do this sampling. We can either perform the procedure just described, or alternatively, sample once from the associated multinomial distribution. Both give counts with the same statistics.  The question is when should we prefer one over the other? Let's give them names

* The *categorical* method. The first method above. (The first step is sampling from the categorical distribution $\mathbf{p}=(p_1,\ldots,p_k)$.)
* The *multinomial* method. The second method above. Draw a single sample from a multinomial distribution.

#### Motivation

Qiskit provides this sampling in various places. For example `quantum_info` and in `qiskit-aer`. Making it efficient is useful, especially if we can reduce the time complexity. Sampling in some regimes can be quick rather than strictly impossible if we use the right method.

#### Results[^1]

* It seems that you can experimentally determine a threshold $\hat{n}/k$ for fixed $k$. If you get $n>{\hat{n}}$, then use the multinomial method, otherwise categorical. This threshold is less that one, usually quite small. In this regime you rarely get more than one count per bin. For $k$ less than about $3000$, it better to use multinomial regardless of $n$. Presented below are some numerical determinations of thresholds assuming we use only numpy functions.

### Details

#### Time complexity
* Both methods are at least linear in $k$, i.e. $O(k)$ in $k$. I guess all reasonable programming language implementations are really $O(k)$.
* The multinomial method is $O(1)$ in $n$. The categorical method is $O(n)$. So for large enough $n$, multinomial is better. (See below for scaling of particular implementations.)
* In practice there are complicating factors: pre- and post-processing, data structures, PL constraints, whether you want to do sampling repeatedly. There are different sub-algorithms that can be chosen for each of the two methods.

### A few of the issues that affect which is better

Note that the multinomial method is always better for large enough $n$ .

* Which method is better will depend on characteristics of $\mathbf{p}$. In experiments, I choose  iid uniformly distributed $p_i$. But you could probably transform sparse $\mathbf{p}$ into a denser array, doing something like this: For every $i$ such that $n p_i\ll 1$ you won't get a count. So filter these out, keeping a smaller denser array, and also keep an array of indices to map the results back to the full $\mathbf{p}$.
* There are several algorithms for sampling from a categorical distribution. Some have an upfront cost. Some don't: Binary search, alias table, etc.
* There are several algorithms for sampling from a multinomial distribution. Some implementations choose among them conditionally. I think the choices are perhaps not always best.
* Language choice. Eg. limitations of numpy. Ability to do multithreading. Libraries available. The same algorithm can perform differently in different compiled languages. Existence and performance of multiple threads?
    * numpy's `multinomial` seems to [unconditionally do](https://github.com/numpy/numpy/blob/50a74fb65fc752e77a2f9e9e2b7227629c2ba953/numpy/random/src/distributions/distributions.c#L1672-L1689) the conditional binomial method.
    * It looks like numpy's `rng.choice` unconditionally does a binary search for a uniform deviate in the cdf.
    [Code is here](https://github.com/numpy/numpy/blob/50a74fb65fc752e77a2f9e9e2b7227629c2ba953/numpy/random/_generator.pyx#L769-L774).
    * So `multinomial` is $O(1)$ in $n$ and $O(k)$ in $k$. And `rng.choice` is $O(n \log(k) + k)$
* The data format expected at the end. It takes extra work to convert one of them to the format of the other. They both have the same penalty to get to the final format.

#### Better way to store counts data

The choice of data structure for counts is not as tightly coupled to the choice of algorithm for generating counts as I first believed. Nonetheless, I'm leaving these observations here.

Currently, the `Counts` class stores counts in two or more `dicts`. The keys are `int`s or `str`s representing either binary or hex numbers. Using numpy-like data instead might be better. This depends on how counts are used. In any case, the most efficient  way to generate counts depends in part on how you want to store them.

* Store data in plain format: best is numpy arrays of some kind of machine ints or floats. Or perhaps a sparse form, like `dict` with `int`s as keys.
* How the data needs to be accessed informs how best to store it. Binary search for values in a sorted array was about 50 times slower than `dict` lookup in a test. Part of this is due to a numpy inefficiency.
* Put info on fancier formats and needed information in meta data.
* Methods to convert to format required by consumer.
* Methods to print or display in friendly or desired format. Eg: 1 -> '00001'.

#### Advantages of basic data types

* Faster to process: read, write, serialize.
* Scales much better than dicts with strings as keys.
* Easier to interoperate with other languages. Eg. compiled languages. They can send and receive arrays of ints and floats.
* Less complexity in code that creates and manipulates them. The complexity is moved to conversion and display routines.

### Benchmarks in numpy

The multinomial method is always better for large enough $n$. I did benchmarks (plot below) to determine the value of $n$ above which multinomial is better.

#### Main results
* The ratio $n / k$, that is number of samples to the number of probabilities doesn't vary too much as $k$ is varied over orders of magnitude.
* The crossover always occurs for $n/k$ well below $1$. This means that the expected number of counts for each $p_i$ is less than $1$. It's probably not useful to sample in this regime. (There are caveats below, eg, this does not consider $\mathbf{p}$ with structure.)

#### Benchmark procedure
This procedure builds a table of thresholds 
1. Loop over a fixed set of values for $k$ (the length of the probability distribution $\mathbf{p}$).
2. Choose a random $\mathbf{p}$. Each of the $k$ elements is iid, uniform on $(0, 1)$. Normalize the result.
3. Choose $n$ the number of samples.
4. Record the time for sampling via the categorical method.
5. Record the time for sampling via the multinomial method.
6. Adjust $n$ via binary search for the value such that the two times are closest. Go to step 3.
   Break when the best $n$ is found.
7. Record the pair $(k, n)$. Recall that $k$ was chosen, and $n$ computed.

#### Using the results to choose a sampling method

* The user sends a distribution $\mathbf{p}$ and a number of samples $n_{in}$. Look up a pair $(k, n)$ in the table by the value of the input $k$. If $n_{in}$ is larger than $n$ from the table, then use the multinomial method. Otherwise use the categorical. There is a threshold in $k$ (around $3000$, depending on the data structure for counts) below which it is always better to use multinomial.

#### More details on the data plotted below.
* Everything was done with numpy. There is code for doing this in C++ and Julia elsewhere in this repo.
* I did the multinomial method two ways: 1) keep the format returned by the numpy function `unique`.
  2) Convert this output to the format produced by `np.nonzero`. The latter is the same format that
  the categorical method returns. There are two curves below. The threshold is of course higher if
  we do the extra conversion step. Purple curve includes conversion. Green curve omits conversion.
* In a third experiment, I did a final conversion of the results of both methods to a dict. The light blue curve shows the result.
* Functions used
    * `rng.uniform` to make $\mathbf{p}$.
    * `rng.choice` to sample from $\mathbf{p}$.
    * `np.unique` to reduce the results in the latter step.
    * `rng.multinomial` to sample from the multinomial distribution.
    * `np.nonzero` and indexing into an array with an array to convert the single array in the
       last step to a pair of arrays similar to those returned by `np.unique`. This final step
        was omitted for the green curve below.

![samples2](./post_proc_results/samples2.png "Plot of sample stats")

[^1]: I overuse bullet points in this markdown to work around a bug that prevents rendering math.

<!--  LocalWords:  ldots multinomial mathbf Qiskit qiskit aer pre numpy iid ints Eg '00001 dicts np
 -->
<!--  LocalWords:  interoperate repo rng multithreading numpy's L1672 L1689 cdf L769 L774 str eg
 -->
<!--  LocalWords:  samples2
 -->
