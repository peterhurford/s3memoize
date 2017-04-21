context("s3memoize")
require(microbenchmark)

expensive_fn <- function(x) { Sys.sleep(0.1); x }
s3memoized_fn <- s3memoize(expensive_fn)

# We don't actually want to make Amazon S3 calls from our test suite
test_with_s3_stub <- function(name, block) {
  test_that(name,
    with_mock(`s3mpi::s3exists` = function(key) !is.null(last_s3[[key]]),
      `s3mpi::s3store` = function(obj, key) { last_s3[[key]] <<- obj },
      `s3mpi::s3read` = function(key) last_s3[[key]],
      last_s3 <- list(),
      block))
}

test_with_s3_stub("it can copy a function", {
  successor <- function(x) x + 1
  s3memoized_successor <- s3memoize(successor)
  expect_equal(s3memoized_successor(2, s3memoize.verbose = FALSE), 3)
})

test_with_s3_stub("it s3memoizes the expensive function", {
  speeds <- summary(microbenchmark(times = 4,
    expensive_fn(2),
    s3memoized_fn(2, s3memoize.verbose = FALSE)
  ))
  expect_true(speeds$median[[2]] < speeds$median[[1]])
})

test_with_s3_stub("it does not rely on memoise for speed", {
  speeds <- summary(microbenchmark(times = 4,
    expensive_fn(2),
    { memoise::forget(s3memoized_fn); s3memoized_fn(2, s3memoize.verbose = FALSE) }
  ))
  expect_true(speeds$median[[2]] < speeds$median[[1]])
})

test_that("it can use just memoise for speed", {
  with_mock(`s3mpi::s3exists` = function(key) FALSE,
    `s3mpi::s3store` = function(obj, key) NULL,
    `s3mpi::s3read` = function(key) NULL,
    speeds <- summary(microbenchmark(times = 4,
      expensive_fn(2),
      s3memoized_fn(2, s3memoize.verbose = FALSE)
    )),
    expect_true(speeds$median[[2]] < speeds$median[[1]])) })

test_with_s3_stub("it can s3memoize a two argument function", {
  adder <- function(x, y) x + y
  s3memoized_adder <- s3memoize(adder)
  expect_equal(s3memoized_adder(2, 3, s3memoize.verbose = FALSE), 5)
})

test_with_s3_stub("it can s3memoize a three argument function", {
  three_adder <- function(x, y, z) x + y + z
  s3memoized_adder <- s3memoize(three_adder)
  expect_equal(s3memoized_adder(1, 2, 3, s3memoize.verbose = FALSE), 6)
})

test_with_s3_stub("it can s3memoize a splat function", {
  s3memoized_paste0 <- s3memoize(paste0)
  expect_equal(s3memoized_paste0("a", "b", "c", "d", "e", s3memoize.verbose = FALSE), "abcde")
})

test_with_s3_stub("it can s3memoize a function with a default and a non-default parameter", {
  adder_with_default <- function(x, y = 10) x + y
  s3memoized_adder <- s3memoize(adder_with_default)
  expect_equal(s3memoized_adder(1, s3memoize.verbose = FALSE), 11)
})

test_with_s3_stub("s3_path warns if being used on an already s3memoized function", {
  s3memoized_identity <- s3memoize(identity)
  expect_warning(get_s3path(s3memoized_identity, 2))
})

test_with_s3_stub("the key used is the same as the key provided by get_s3path", {
  s3memoized_identity <- s3memoize(identity)
  s3memoized_identity(2, s3memoize.verbose = FALSE)
  expect_true(s3mpi::s3exists(get_s3path(identity, 2)))
})

test_with_s3_stub("keys that are not written to do not exist in s3", {
  s3memoized_identity <- s3memoize(identity)
  s3memoized_identity(2, s3memoize.verbose = FALSE)
  expect_false(s3mpi::s3exists(get_s3path(identity, 3)))
})

test_with_s3_stub("precompiling the arguments is the same as putting the arguments in directly", {
  precompiled_args <- c(1, 2, 3)
  expect_equal(get_s3path(identity, list(precompiled_args)),
    get_s3path(identity, list(c(1, 2, 3))))
})

test_with_s3_stub("identical functions are s3memoized the same, regardless
  of whether they are named differently I", {
    identity_by_any_other_name_would_smell_as_sweet <- identity
    expect_equal(get_s3path(identity, 2),
      get_s3path(identity_by_any_other_name_would_smell_as_sweet, 2))
})

test_with_s3_stub("identical functions are s3memoized the same, regardless of
  whether they are named differently II", {
    identity_by_any_other_name_would_smell_as_sweet <- function(x) x
    expect_equal(get_s3path(identity, 5),
      get_s3path(identity_by_any_other_name_would_smell_as_sweet, 5))
})

test_with_s3_stub("the path is the same if done twice I", {
  fn <- function(x) x
  first_time <- get_s3path(fn, 6)
  second_time <- get_s3path(fn, 6)
  expect_equal(first_time, second_time)
})

test_with_s3_stub("the path is the same if done twice II", {
  fn <- function(x) x
  first_time <- get_s3path(fn, 7)
  fn <- function(x) x
  second_time <- get_s3path(fn, 7)
  expect_equal(first_time, second_time)
})

test_with_s3_stub("the path is the same if done twice III", {
  fn <- function(x) x
  cached_fn <- s3memoize(fn)
  first_time <- cached_fn(8, s3memoize.verbose = FALSE)
  second_time <- cached_fn(8, s3memoize.verbose = FALSE)
  expect_equal(first_time, second_time)
})

test_with_s3_stub("the path is the same if done twice IV", {
  fn <- function(x) x
  cached_fn <- s3memoize(fn)
  first_time <- cached_fn(9, s3memoize.verbose = FALSE)
  fn2 <- function(x) x
  cached_fn2 <- s3memoize(fn2)
  second_time <- cached_fn2(9, s3memoize.verbose = FALSE)
  expect_equal(first_time, second_time)
})

test_with_s3_stub("I can get the before fn", {
  fn <- function(x) x
  cached_fn <- s3memoize(fn)
  expect_equal(fn, get_before_fn(cached_fn))
})

test_with_s3_stub("printing involves the before fn", {
  fn <- function(x) x
  cached_fn <- s3memoize(fn)
  called <- FALSE
  with_mock(`get_before_fn` = function(...) { called <<- TRUE }, {
    expect_false(called)
    print(cached_fn)
    expect_true(called)
  })
})
