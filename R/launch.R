#' Launch betScrapeR shiny app
#'
#' \code{launch} an interactive visualisation version of betScrapeR.
#'  It's structure is taken from a post by
#' \href{http://deanattali.com/2015/04/21/r-package-shiny-app/}{Dean Attali}
#'
#' @param sport The name of sport for which an app available. Currently, the only
#' accepted parameters are "horseRacing" and "tennis".
#'
#' @return No value is returned, but a seperate window for the app is launched.
#'
#' @examples
#' \dontrun{
#' ## Launch horse racing app
#' launch("horseRacing")
#' ## Launch tennis app
#' launch("tennis")
#' ## See a a list of accepted sports
#' launch()
#' ## Note: An error message will appear on the app if you haven't installed
#' ## the dependent packages or if you don't have a valid Betfair session token.
#' }
#'

launch <- function(sport) {
  # locate all the shiny app examples that exist
  validExamples <- list.files(system.file("shiny-examples", package = "betScrapeR"))

  validExamplesMsg <-
    paste0(
      "Valid examples are: '",
      paste(validExamples, collapse = "', '"),
      "'")

  # if an invalid sport is given, throw an error
  if (missing(sport) || !nzchar(sport) ||
      !sport %in% validExamples) {
    stop(
      'Please run `launch()` with a valid app as an argument.\n',
      validExamplesMsg,
      call. = FALSE)
  }

  # find and launch the app
  appDir <- system.file("shiny-examples", sport, package = "betScrapeR")
  shiny::runApp(appDir, display.mode = "normal")
}
