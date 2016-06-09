#' s3memoize maps a function to a s3memoized version of that function.
#'
#' @param fn function. Function to s3memoize.
#' @import checkr
#' @export
s3memoize <- checkr::ensure(
  pre = fn %is% "function",
  function(fn) {
    if (s3memoize::is.s3memoized(fn)) return(fn)
    force(fn)
    out_fn <- function(..., s3memoize.reload = FALSE, s3memoize.verbose = TRUE) {
      digest_path <- s3memoize::get_s3path(fn, ...)
      if (isTRUE(s3memoize.reload)) memoise::forget(fn)
      if (!isTRUE(s3memoize.reload) && s3mpi::s3exists(digest_path)) {
        if (isTRUE(s3memoize.verbose)) cat(paste(c("Reading from S3...", digest_path, "\n")))
        return(s3mpi::s3read(digest_path))
      }
      result <- fn(...)
      if (isTRUE(s3memoize.verbose)) cat(paste("Storing to S3...", digest_path))
      s3mpi::s3store(result, digest_path)
      if (isTRUE(s3memoize.verbose)) cat(" Stored.\n")
      result
    }
    mout_fn <- memoise::memoise(out_fn)
    attr(mout_fn, "s3memoized") <- TRUE
    attr(mout_fn, "memoised") <- TRUE
    class(mout_fn) <- c("s3memoized_function", "function")
    mout_fn
  })
