#' A helper method to fetch the name of the s3 path that a certain call is stored in.
#' @param fn function. The function to find the digest for.
#' @param ... Arguments passed to the function that the digest is for.
#' @import checkr
#' @export
get_s3path <- function(fn, ...) {
    if (is.s3memoized(fn)) {
      fn <- s3memoize::get_before_fn(fn)
      warning("fn is s3memoized.  Extracting path from the before_fn instead.")
    }
    fn_digest <- list(digest::digest(list(as.character(formals(fn)), as.character(body(fn)))))
    args_digest <- digest::digest(list(fn_digest, list(...)))
    paste0("s3memoize/", args_digest)
  }


#' A helper method to determine if a function is already s3memoized.
#' @param fn function. The function to test.
#' @import checkr
#' @export
is.s3memoized <- checkr::ensure(
  pre = fn %is% "function",
  post = result %is% logical,
  function(fn) {
    isTRUE(attr(fn, "s3memoized")) || methods::is(fn, "s3memoized_funcion")
  })


#' A helper method to get the pre-s3memoize function of a s3memoized function.
#' @param fn function. The s3memoized function to look for.
#' @import checkr
#' @export
get_before_fn <- checkr::ensure(
  pre = fn %is% s3memoized_function,
  post = list(result %is% "function", result %isnot% s3memoized_function),
  function(fn) { environment(environment(fn)[["_f"]])$fn })


#' Print batched functions as they once were.
#' @param x function. The function to print.
#' @param ... additional arguments to pass to print.
#' @export
print.s3memoized_function <- function(x, ...) {
  print(list(before_fn = s3memoize::get_before_fn(x), after_fn = body(x)), ...)
}
