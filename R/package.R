
#' Debug R Packages
#'
#' Specify debug messages as special string constants, and control
#' debugging of packages via environment variables.
#'
#' To add debugging to your package, you need to
#' 1. Import the `debugme` package.
#' 2. Define an `.onLoad` function in your package, that calls `debugme`.
#'    An example:
#'    ```r
#'    .onLoad <- function(libname, pkgname) { debugme::debugme() }
#'    ```
#'
#' By default debugging is off. To turn on debugging, set the `DEBUGME`
#' environment variable to the names of the packages you want to debug.
#' Package names can be separated by commas.
#'
#' Note that `debugme` checks for environment variables when it is starting
#' up. Environment variables set after the package is loaded do not have
#' any effect.
#'
#' Example `debugme` entries:
#' ```
#' "!DEBUG Start Shiny app"
#' ```
#'
#' @section Dynamic debug messsages:
#'
#' It is often desired that the debug messages contain values of R
#' epxressions evaluated at runtime. For example, when starting a Shiny
#' app, it is useful to also print out the path to the app. Similarly,
#' when debugging an HTTP response, it is desired to log the HTTP status
#' code.
#'
#' `debugme` allows embedding R code into the debug messages, within
#' backticks. The code will be evaluated at runtime. Here are some
#' examples:
#' ```
#' "!DEBUG Start Shiny app at `path`"
#' "!DEBUG Got HTTP response `httr::status_code(reponse)`"
#' ```
#'
#' Note that parsing the debug strings for code is not very sophisticated
#' currently, and you cannot embed backticks into the code itself.
#'
#' @section Redirecting the output:
#'
#' If the `DEBUGME_OUTPUT_FILE` environment variable is set to
#' a filename, then the output is written there instead of the standard
#' output stream of the R process.
#'
#' @param env Environment to instument debugging in. Defaults to the
#'   package environment of the calling package.
#' @param pkg Name of the calling package. The default should be fine
#'   for almost all cases.
#'
#' @docType package
#' @name debugme
#' @export

debugme <- function(env = topenv(parent.frame()),
                    pkg = environmentName(env)) {

  ## Are we debugging this package?
  if (! pkg %in% names(debug_data$palette)) return()

  objects <- ls(env, all.names = TRUE)
  funcs <- Filter(function(x) is.function(get(x, envir = env)), objects)
  Map(
    function(x) assign(x, instrument(get(x, envir = env)), envir = env),
    funcs
  )
}

debug_data <- new.env()
debug_data$timestamp <- NULL

.onLoad <- function(libname, pkgname) {
  pkgs <- parse_env_vars()
  initialize_colors(pkgs)
  initialize_output_file()
}

parse_env_vars <- function() {
  env <- Sys.getenv("DEBUGME")
  strsplit(env, ",")[[1]]
}

initialize_output_file <- function() {
  out <- Sys.getenv("DEBUGME_OUTPUT_FILE", "")
  if (out == "") {
    debug_data$output_file <- NULL
  } else {
    debug_data$output_file <- out
    debug_data$output_fd <- file(out, open = "a")
  }
}
