#' Launch betScrapeR shiny app
#'
#' \code{launch} an interactive visualisation version of betScrapeR. As there's
#' currently only one app available (I may do more in the future-
#' e.g. tennis app, football app, etc), this function takes no
#' arguments. It's structure is taken from a post by
#' \href{http://deanattali.com/2015/04/21/r-package-shiny-app/}{Dean Attali}
#'
#' @return No value is returned, but a seperate window for the app is launched.
#'
#' @examples
#' \dontrun{
#' launch()
#' ## Note: An error message will appear on the app if you haven't installed
#' ## the dependent packages or if you don't have a valid Betfair session token.
#' }
#'

launch <- function() {
  appDir <- system.file("shiny-examples", "myapp", package = "betScrapeR")
  if (appDir == "") {
    stop("Could not find example directory. Try re-installing `betScrapeR`.", call. = FALSE)
  }

  shiny::runApp(appDir, display.mode = "normal")
}
