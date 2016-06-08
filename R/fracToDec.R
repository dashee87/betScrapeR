#' Convert odds from fraction to decimal
#' 
#' \code{partialMatch} converts betting odds from fraction to decimal. By
#' default, Oddschecker provides odds as fractions, while the exchange utilise
#' decimal odds. To allow easier comparision, we need to convert the fractional
#' odds to decimal. The function also returns negative under specific scenarios
#' (e.g. no odds).
#' 
#' 
#' @param price String. A string representing the odds of a bet, expressed in
#'   fractional form (e.g. 5/4).
#'   
#' @return The output of the function is a numeric. In the event of "SP", 0.0 is
#'   returned, while "" is conveted -1.0.
#'   
#' @examples
#' \dontrun{
#' 
#' # 2.25 is the decimal form of "5/4"
#' 
#' fracToDec("5/4")
#' 
#' # We can map a vector of fractional odds to their decimal form equivalent
#' 
#' sapply(c("5/4","8/11","4/6","5","22/2"),fracToDec)
#' 
#' # Finally, sometimes the odds are not provided, or at least not in fractional form. To account for this, specific numbers are returned.
#' 
#' sapply(c("EVS","SP",""),fracToDec)
#' 
#' }

fracToDec <- function(price){
  if(price=="EVS")
    return(2.0) 
  else if(price=="")
    return(-1.0) 
  else if(price=="SP")
    return(0.0) 
  else(return(eval(parse(text=price))+1))
}