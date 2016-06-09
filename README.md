## S3Memoize <a href="https://travis-ci.org/peterhurford/s3memoize"><img src="https://img.shields.io/travis/peterhurford/s3memoize.svg"></a> <a href="https://codecov.io/github/peterhurford/s3memoize"><img src="https://img.shields.io/codecov/c/github/peterhurford/s3memoize.svg"></a> <a href="https://github.com/peterhurford/s3memoize/tags"><img src="https://img.shields.io/github/tag/peterhurford/s3memoize.svg"></a>

Caching in R has been made great by Hadley's [Memoise](http://www.github.com/hadley/memoise) package, which memoizes functions.  However, this memoization only lasts for your R session.  Once you close your R session, the cache is gone.

Sometimes we have computationally complex functions that really don't change much, if at all.  In that case, when we cache it, we want to cache it for good -- across R sessions!

One solution to that is to store the information in S3.  Robertzk accomplishes this with his [S3MPI package](https://github.com/robertzk/s3mpi).

However, the interface for storing and retrieving a function in S3 via the S3MPI package is clunky.  And the individual calls to S3 are slow.

We can solve the clunkiness by creating a nice package to wrap S3MPI.  And we can speed up calls to S3 by wrapping with Hadley's memoise, so you only have to call S3 once in any R session.

Therefore, [S3MPI](http://www.github.com/robertzk/s3mpi) + [Memoise](http://www.github.com/hadley/memoise) = S3Memoize (with a Z).  Simple, persistent caching in R.


## Caching
```R
cf <- s3memoize(f)
```


## Uncaching
There's currently no way to drop the S3 cache.  However, if you want to force a reload of the cache for a particular call (without affecting the caches of other calls), you can run as follows:
```R
cf(x, s3memoize.reload = TRUE)
```


## Test if the function is cached?
```R
s3memoize::is.s3memoized(cf) # TRUE
s3memoize::is.s3memoized(f) # FALSE
```

Also, plays nicely with Memoise:
```R
memoise::is.memoised(cf) # TRUE
memoise::is.memoised(f) # FALSE
```


## Installation
This package is not yet available from CRAN. To install the latest development builds directly from GitHub, run this instead:

```R
if (!require('devtools')) install.packages('devtools')
  devtools::install_github('peterhurford', 's3memoize')
```

You may also need to install some of the dependencies:

```R
if (!require('devtools')) install.packages('devtools')
if (!require('s3mpi')) install_github('robertzk/s3mpi')
if (!require('memoise')) install.packages('memoise')
```


## Other cool things

If you ever need the S3 path that the function stores in, use `get_s3path(name_of_function, list_of_args)`
```R
> get_s3path(identity, list(2))
[1] "s3memoize/90dcfd2ef1717f070378928221d65072"
```

If you're annoyed by all the statements made by S3Memoize, use `s3memoize.verbose = FALSE`
```R
> fn <- s3memoize(identity)
> fn(2)
Reading from S3... s3memoize/90dcfd2ef1717f070378928221d65072
[1] 2
> fn(2, s3memoize.verbose = FALSE)
[1] 2
```
