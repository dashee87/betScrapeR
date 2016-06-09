#' Visualise current betting odds for a specific horse race
#'
#' \code{horseScraper} returns the current betting odds (exchange & bookies
#' combined) for a specific horse race. This information can then be used as the
#' basis of particular trading strategies.
#'
#' Note on \code{horseScraper}: Currently, this function does not support horse
#' races in Australia and New Zealand.
#'
#' @seealso \url{https://github.com/phillc73/abettor} for general information on
#' making betfair API calls. This function is reliant on numerous functions from
#' this package: a valid session token must be present; the input for
#' horseScraper is horse race data generated from an appropriate
#' listMarketCatalogue call; current exchange price data is gathered from a
#' listMarketBook call within horseScraper
#'
#' @param race dataframe (output from abettor:istMarketCatalogue call).
#'   Required. No default.
#'
#' @param suppress Boolean. A warning is posted when the race start is less than
#'   15 mins away (data may not be reliable as prices change quite quickly just
#'   before the start). Setting this parameter to FALSE suppresses this warning.
#'   Default is TRUE. Optional.
#'
#' @param numAttempts integer. Specifies the number of attempts before aborting
#'   this particular scraping attempt (see \code{\link{scrapePage}}). Optional.
#'   Default is 5.
#'
#' @param sleepTime integer. This parameter specifies the amount of time (in
#'   seconds) the function waits following a failed scraping attempt. Optional.
#'   Default is zero.
#'
#' @return If successful, this function will return a dataframe. The columns
#'   represent the current betting data for each active horse in the race. This
#'   betting data consists of both exchange information (back/lay price and
#'   odds) and the odds offered by various bookies. If unsuccessful, an error
#'   dataframe is returned. There are various reasons why an error dataframe is
#'   returned (race has finsihed, race is not covered by Oddschecker, etc). The
#'   precise reason for the failure will be outlined in the error dataframe.
#'
#' @section Note on \code{race.time} variable: The API returns the event start
#'   time in UTC. During Daylight Savings Time (DST), we need to an hour
#'   manually.
#'
#' @examples
#' \dontrun{
#'
#' # Make sure that loginBF has been called, as this function requires
#' a valid session token.
#'
#' # Only one race can be passed to function at a time. Let's have a look at the
#' current odds for an upcoming horse race. To do so, we call listMarketCatalogue
#'
#' HRaces=listMarketCatalogue(eventTypeIds = "7",marketTypeCodes = "WIN")
#' horseScraper(HRaces[1])
#'
#' # If we want to return data for numerous races, we'd need to loop the HRaces dataframe
#'
#' for(i in 1:nrow(HRaces)){
#' print(HRaces[i,]$event)
#' print(horseScraper(HRaces[i,]))
#' }
#'
#' }


horseScraper=function(race, suppress = FALSE, numAttempts = 5, sleepTime = 0){
  if(is.null(race$event$venue)|is.null(race$event$countryCode)|is.null(race$marketId)|is.null(race$marketStartTime)|is.null(race$runners))
    return(data.frame(error="Insufficient race data"))
  race.time=as.POSIXct(race$marketStartTime,format="%Y-%m-%dT%H:%M","Europe/London")
  race.time=race.time+ 60*60*(format(race.time,format="%Z")=="BST")
  if(difftime(race.time,format(Sys.time(), tz="Europe/London",usetz=TRUE))<0.25 & suppress == FALSE){
      warning("Race starts in less than 15 minutes. Be careful. Prices may fluctuate quickly!")
    }
  betfair.horses <- race$runners[[1]]$runnerName
  betfair.info <- abettor::listMarketBook(marketIds=race$marketId, priceData = "EX_BEST_OFFERS")
  if(betfair.info$status=="CLOSED"){
    return(data.frame(error="That market is closed",marketId=race$marketId))
  }
  if(length(betfair.info)==0)
    return(data.frame(error="No market data returned. Invalid market ID and/or session token expired?"))
  if(!is.null(betfair.info$message)){
    return(data.frame(data.frame(error="listMarketBook error"),betfair.info))}
  betfair.horses <- betfair.horses[match(betfair.info$runners[[1]]$selectionId,race$runners[[1]]$selectionId)]
  runners <- which(betfair.info$runners[[1]]$status=="ACTIVE")
  betfair.horses <- betfair.horses[which(betfair.info$runners[[1]]$status=="ACTIVE")]
  if(any(grepl("[0-9]",betfair.horses))){
    betfair.horses <- gsub("^[^ ]* ","",betfair.horses)
  }
  betfair.horses <- gsub("[[:punct:]]", "", betfair.horses)
  betfair.back <- unlist(lapply(betfair.info$runners[[1]]$ex$availableToBack[runners],function(x){if(length(x)==0){data.frame(price=NA,size=NA)}else{as.data.frame(x)[1,]}}), use.names = FALSE)
  betfair.lay <- unlist(lapply(betfair.info$runners[[1]]$ex$availableToLay[runners],function(x){if(length(x)==0){data.frame(price=NA,size=NA)}else{as.data.frame(x)[1,]}}), use.names = FALSE)
  betfair.prices <- rbind(betfair.info$runners[[1]]$selectionId[runners],as.data.frame(matrix(betfair.back,2,length(betfair.horses))),
                      as.data.frame(matrix(betfair.lay,2,length(betfair.horses))))
  colnames(betfair.prices) <- betfair.horses
  row.names(betfair.prices) <- c("Selection ID","Back Price","Back Size","Lay Price","Lay Size")
  if( race$event$countryCode=="GB" |  race$event$countryCode == "IE"){
    page <- scrapePage(paste0("http://www.oddschecker.com/horse-racing/",substring(race$marketStartTime,1,10),"-",gsub(" ","-",tolower(race$event$venue)),"/",substring(race.time,12,16),"/winner"),numAttempts,sleepTime)
  }else if(race$event$countryCode=="FR"|race$event$countryCode=="DE"){
    if(as.Date(format(as.POSIXct(Sys.time(),format="%Y-%m-%dT%H:%M","UTC"),tz=race$event$timezone))==as.Date(format(as.POSIXct(Sys.time(),format="%Y-%m-%dT%H:%M","UTC"),tz="Europe/London"))){
      page <- scrapePage(paste0("http://www.oddschecker.com/horse-racing/europe/",formatVenue(race$event$venue),"/",substring(race.time,12,16),"/winner"),numAttempts,sleepTime)
    }else{page <- scrapePage(paste0("http://www.oddschecker.com/horse-racing/europe/",substring(race$marketStartTime,1,10),"-",formatVenue(race$event$venue),"/",substring(race.time,12,16),"/winner"),numAttempts,sleepTime)}
  }else if(race$event$countryCode=="US"|race$event$countryCode=="CL"){
    if(as.Date(format(as.POSIXct(Sys.time(),format="%Y-%m-%dT%H:%M","UTC"),tz=race$event$timezone))==as.Date(format(as.POSIXct(Sys.time(),format="%Y-%m-%dT%H:%M","UTC"),tz="Europe/London"))){
      page <- scrapePage(paste0("http://www.oddschecker.com/horse-racing/americas/",formatVenue(race$event$venue),"/",substring(race.time,12,16),"/winner"),numAttempts,sleepTime)
    }else{page <- scrapePage(paste0("http://www.oddschecker.com/horse-racing/americas/",substring(race$marketStartTime,1,10),"-",formatVenue(race$event$venue),"/",substring(race.time,12,16),"/winner"),numAttempts,sleepTime)}
  }else if(race$event$countryCode=="ZA"|race$event$countryCode=="SG"){
    if(as.Date(format(as.POSIXct(Sys.time(),format="%Y-%m-%dT%H:%M","UTC"),tz=race$event$timezone))==as.Date(format(as.POSIXct(Sys.time(),format="%Y-%m-%dT%H:%M","UTC"),tz="Europe/London"))){
      page <- scrapePage(paste0("http://www.oddschecker.com/horse-racing/world/",formatVenue(race$event$venue),"/",substring(race.time,12,16),"/winner"),numAttempts,sleepTime)
    }else{page <- scrapePage(paste0("http://www.oddschecker.com/horse-racing/world/",substring(race$marketStartTime,1,10),"-",formatVenue(race$event$venue),"/",substring(race.time,12,16),"/winner"),numAttempts,sleepTime)}
  }else{return(data.frame(error="Country not covered by OddsChecker"))}
  if(is.data.frame(page))
    return(page)
  bookies <- html_nodes(page,".eventTableHeader aside") %>% html_text()
  if(length(bookies) == 0){
    return(data.frame(error="No racing data scraped- Is that race covered by OddsChecker?"))
  }
  horse <- html_nodes(page,".nm") %>% html_text()
  if(length(horse) == 1){
    horse <- betfair.horses
    odds <- rep(0,length(betfair.horses)*length(bookies))
  }else{horse <- gsub("[[:punct:]]", "", horse)
    if(length(intersect(horse,betfair.horses))==0)
      return(data.frame(error="Events don't match up- No horses in common"))
    horse <- betfair.horses[partialMatch(tolower(horse[!grepl(" NR",horse)]),tolower(betfair.horses))]
    odds <- html_nodes(page,".bc .np , .bs") %>% html_text() %>% sapply(fracToDec)}

  checker <- as.data.frame(matrix(odds,length(bookies),length(horse)))
  colnames(checker) <- horse
  if(length(bookies)==25){
    rownames(checker)=c("Bet365","Skybet","totesport","BoyleSports","Betfred","Sporting Bet","Bet Victor","Paddy Power","Stan James",
                         "888","Ladbrokes","Coral","William Hill","Winner","Betfair Sportsbook","Betway","Betbright","Netbet",
                         "Racebets","32Red","10bet","Marathon Bet","188bet","Betfair Exchange","Betdaq")
  }else if(length(bookies)==24){
    rownames(checker)=c("Bet365","Skybet","totesport","BoyleSports","Betfred","Sporting Bet","Bet Victor","Paddy Power","Stan James",
                           "888","Ladbrokes","Coral","William Hill","Winner","Betfair Sportsbook","Betway","Netbet",
                           "Racebets","32Red","10bet","Marathon Bet","188bet","Betfair Exchange","Betdaq")
  }else{return(data.frame(error="Invalid # Bookies",number=length(bookies)))}
  checker <- checker[1:(nrow(checker)-2),]
  nr.horses=betfair.horses[!betfair.horses %in% horse]
  if(length(nr.horses)!=0){
    checker[,(length(checker)+1):(length(checker)+length(nr.horses))] <- -101
    colnames(checker)[(length(checker)-length(nr.horses)+1):length(checker)] <- nr.horses
  }
  return(rbind(betfair.prices, checker[,names(betfair.prices)]))
}
