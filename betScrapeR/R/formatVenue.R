#' COnverts Betfair formatted venues to OddsChecker compatible venues
#' 
#' \code{formatVenue} is a simple function that converts Betfair API venues to 
#' OddsChecker compatible venues (lower case hypehnated separated strings). The
#' venue nomenclature appears quite consistent in the UK and Ireland. However,
#' especially in the Americas, Betfair and Oddschecker may have different names
#' for the same venue. To allow Betfair API data to be combined with scraped
#' OddsChecker data, we need to ensure that venue names match up. The list of
#' venues is not necessarily exhausitive and potential omissions should be
#' raised as issue or pull request.
#' 
#' 
#' @param venue string. The name of the horse racing venue to be converted.
#'   
#' @return A string of the Oddschecker compatible venue is returned.
#'   
#'   
#' @examples
#' \dontrun{
#' 
#' # Simple venue conversion
#' 
#' formatVenue("Emerald Downs")
#' 
#' # Example where Betfair and Oddschecker differ significantly
#' 
#' formatVenue("Parx Racing At Philadelphia Park")
#' }

formatVenue=function(venue){
if(venue=="Valparaiso Sporting Club")
  return("valparaiso")
else if (venue=="Parx Racing At Philadelphia Park"|venue=="Parx Racing")
  return("philadelphia-park")
else if (venue=="Club Hipico De Concepcion")
  return("concepcion")
else if (venue=="Hipodromo Chile")
    return("hipo-chile")
else if (venue=="Bordeaux")
  return("bordeaux-le-bouscat")
else if (venue=="Mountaineer Casino Racetrack & Resort")
  return("mountaineer-park")
else{
return(gsub(" ","-",tolower(venue)))}
}