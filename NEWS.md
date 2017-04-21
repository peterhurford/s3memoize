#### 0.2.1

* Fixed a bug with checkr.

# 0.2.0

* Fixed the function serialization to not depend on the environment outside the function.
* `get_s3path` now takes arguments via a splat (...) rather than a passed list.
* `get_s3path` is now used by the main `s3memoize` function to calculate paths.
