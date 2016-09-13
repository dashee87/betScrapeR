#' Visualise current betting odds for a specific tennis match
#'
#' \code{tennisScraper} returns the current betting odds (exchange & bookies
#' combined) for a specific tennis match. This information can then be used as the
#' basis of particular trading strategies.
#'
#' @seealso \url{https://github.com/phillc73/abettor} for general information on
#'   making betfair API calls. This function is reliant on numerous functions
#'   from this package: a valid session token must be present; current exchange price data is gathered from a
#'   listMarketBook call within horseScraper.
#'
#' @param type string. Determines the type of input used to match up the Betfair exchange and Oddschecker.
#' There are three options: df, name and id. df: A data frame should be passed to the function as the match parameter
#' (see below); name: the name (or part of a name) of a tennis player should be passed to the function as the match parameter;
#' id: a betfair event id (e.g. 20234123) or market id  (e.g. 1.23121132) should be passed to the function as the match parameter.
#'
#' @param match dataframe (output from abettor:istMarketCatalogue call) or string (player name or event/market id). The class of this
#'  parameter should be specified in the type parameter (see above). A dataframe is the recommended
#'  choice, as it involves the least computational work. If a string is passed, then the function finds
#'  the event on the Betfair exchange that corresponds to that player name or event/market id.
#'  Required. No default.
#'
#' @param inplay boolean. Only relevant when type is not df. Setting inplay to TRUE means that only inplay
#' teniis matches will be searched for a matching player name or market/event id. Setting inpay to FALSE
#' means inplay matches will be excluded from the search. Finally, NULL means that both inplay and preplay matches will be searched.
#' Tennis odds can change rapidly inplay (possibly after a every point). The Oddschecker feed may not be quick enough to capture these quick changes. So, if you intend to use this function
#' for arbing, be aware that inplay arbs can arise from old odds still being on the Oddschecker site.
#' Optional. Default is NULL.
#'
#' @param tennis_links <character>. A vector of tennis match page links on the oddschecker page. If not provided,
#' the function scrapes all the match page links on the Oddschecker tennis page. As links are quite static,
#' to speed up function, you can pass a vector of links to function. Consult the tennis tutorial on github to see how you can
#' generate this vector of links.
#'
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
#'   represent the current betting data for each player/doubles team. This
#'   betting data consists of both exchange information (back/lay price and
#'   odds) and the odds offered by various bookies. If unsuccessful, an error
#'   dataframe is returned. There are various reasons why an error dataframe is
#'   returned (match has finsihed, match is not covered by Betfair/Oddschecker, etc). The
#'   precise reason for the failure will be outlined in the error dataframe.
#'   Note that the data frame returned by this function may include non-positive
#'   integers. This is to cover cases where the actuals couldn't be
#'   scraped from Oddschecker. For example, -1 means that no price was listed for
#'   that particular player.
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
#' all_matches=listMarketCatalogue(eventTypeIds = "2",marketTypeCodes = "MATCH_ODDS")
#' tennisScraper("df", all_matches[1,])
#'
#' # If we want to return data for numerous races, we'd need to loop the matches dataframe
#'
#' for(i in 1:nrow(all_matches)){
#' print(all_matches[i,]$event)
#' print(tennisScraper("df", all_matches[i,]))
#' }
#'
#' # But if we don't have a data frame, we can also pass a player's name (case insensitive)
#'
#' tennisScraper("name", "djokovic")
#'
#' # Alternatively, if we know the event id or market id of Djokovic's match on the Betfair exchange
#'
#' tennisScraper("id", "27916958") # event id
#'
#' tennisScraper("id", "1.126673586") #market id
#'
#' }


tennisScraper=function(type, match, inplay = NULL,
                       tennis_links = NULL, numAttempts = 5, sleepTime = 0){
  doubles <- FALSE

  if(!type %in% c("df","name","id"))
    return(data.frame(error="Invalid type. Call ?tennisScraper for more details."))
  if(type == "df"){
    # checking whether the data frame has runner information
    # from which we'll extract the tennis players names
    if(!any(c("runners","runnerName")  %in% colnames(match)))
      return(data.frame(error="No runner information in data frame"))
    if(! "marketId" %in% colnames(match))
      return(data.frame(error="No marketId in data frame"))

    input <- match

  }else{

    betfair_tennis <- abettor::listMarketCatalogue(eventTypeIds = "2", marketTypeCodes = "MATCH_ODDS", inPlayOnly = inplay,
                                                   marketProjection = c("RUNNER_DESCRIPTION","EVENT"),
                                                   fromDate = format(Sys.time() - 60*60*24, "%Y-%m-%dT%TZ"),
                                                   toDate = format(Sys.time() + 60*60*72, "%Y-%m-%dT%TZ")
    )
    if(length(betfair_tennis) == 3)
      return(data.frame(error="Error returned by listMarketCatalogue. Are you logged in?"))
    if(nrow(betfair_tennis) == 0)
      return(data.frame(error="No data returned by listMarketCatalogue."))

    if(type == "name"){
      # I've no doubt there are ways to speed this up (dplyr, data tables, etc)
      # But I've started with a general philosophy of using base r when possible rather than
      # being dependent on packages
      betfair_players <- unlist(lapply(betfair_tennis$runners,function(x){x[,"runnerName"]}))

      name_matches <- which(grepl(match, betfair_players, ignore.case = TRUE))

      if(length(name_matches) == 0)
        return(data.frame(error="Couldn't find that name in any Betfair tennis match"))

      if(length(name_matches) > 1)
        return(data.frame(error="Name found in multiple Betfair tennis matches. Please be more specific",
                          matches= paste(betfair_tennis[ceiling(name_matches/2),]$event$name,collapse=" & "))
        )

      input <- betfair_tennis[ceiling(name_matches/2),]
    }

    if(type == "id"){

      if(grepl("\\.", match)){
        id_match <- which(betfair_tennis$marketId == toString(match))
      }else{
        id_match <- which(betfair_tennis$event$id == toString(match))
      }

      if(length(id_match) == 0)
        return(data.frame(error="Couldn't find any Betfair tennis market for that id."))

      input <- betfair_tennis[id_match,]
    }
  }
  # remove the forward slashes for doubles matches
  betfair_players <- gsub("/", " ", input$runners[[1]]$runnerName)

  betfair_info <- abettor::listMarketBook(marketIds = input$marketId, priceData = "EX_BEST_OFFERS")

  if(length(betfair_info)==0)
    return(data.frame(error="No market data returned. Invalid market ID and/or session token expired?"))

  if(betfair_info$status=="CLOSED")
    return(data.frame(error="That market is closed",marketId=match$marketId))

  if(!is.null(betfair_info$message))
    return(data.frame(data.frame(error="listMarketBook error"),betfair_info))

  if(any(betfair_info$runners[[1]]$status!="ACTIVE"))
    return(data.frame(data.frame(error="Not active market on betfair"),betfair_info))

  betfair_players <- betfair_players[match(betfair_info$runners[[1]]$selectionId,input$runners[[1]]$selectionId)]

  betfair_back <- unlist(lapply(betfair_info$runners[[1]]$ex$availableToBack,function(x){
    if(length(x)==0){data.frame(price=NA,size=NA)}else{as.data.frame(x)[1,]}}), use.names = FALSE)

  betfair_lay <- unlist(lapply(betfair_info$runners[[1]]$ex$availableToLay,function(x){
    if(length(x)==0){data.frame(price=NA,size=NA)}else{as.data.frame(x)[1,]}}), use.names = FALSE)

  betfair_prices <- rbind(as.data.frame(matrix(betfair_back,2,length(betfair_players))),
                          as.data.frame(matrix(betfair_lay,2,length(betfair_players))))
  colnames(betfair_prices) <- betfair_players
  row.names(betfair_prices) <- c("Back Price","Back Size","Lay Price","Lay Size")

  # if oddschecker match page links weren't passed as an argument, then we must scrape them ourselves
  if(is.null(tennis_links)){

    page <- "http://www.oddschecker.com/tennis/match-coupon"
    scraped <- betScrapeR::scrapePage(page, numAttempts, sleepTime)
    if(is.data.frame(scraped))
      return(page)

    tennis_links <- rvest::html_nodes(scraped, "a") %>% rvest::html_attr("href")
    tennis_links <- tennis_links[!grepl("://www.", tennis_links)]
  }

  if(length(tennis_links) == 0){
    return(data.frame(error="No links on Oddschecker"))
  }

  link_matches <- apply(sapply(tolower(unlist(strsplit(betfair_players," "))),
                               function(x){grepl(x,tennis_links)}),1,sum)

  if(max(link_matches) < 3)
    return(data.frame(error="Couldn't find a link for that match on Oddschecker"))

  match_page <- tennis_links[which.max(link_matches)]

  scraped_match <- betScrapeR::scrapePage(paste0("http://www.oddschecker.com/",match_page), numAttempts, sleepTime)

  if(is.data.frame(scraped_match))
    return(scraped_match)

  bookies <- rvest::html_nodes(scraped_match,".eventTableHeader .bk-logo-click") %>%  rvest::html_attr(name = "title")

  if(length(bookies) == 0){
    return(data.frame(error="No match data scraped from page."))
  }
  oddschecker_players <- rvest::html_nodes(scraped_match,".nm") %>% rvest::html_text()

  if(length(oddschecker_players)!=2)
    return(data.frame(error="I'm seeing more/less than two tennis players in that match",
                      message=paste(oddschecker_players,collapse=", ")))

  if(all(grepl("/",oddschecker_players))){
    doubles <- TRUE
    oddschecker_players <- gsub("/", " ", oddschecker_players)
    doubles_split <- strsplit(oddschecker_players, " ")
    if(any(sapply(doubles_split,length)!=4))
      return(data.frame(error="I'm not seeing 4 players in that doubles match",
                        message=paste("Players:",paste(oddschecker_players,collapse=" & "))))
    oddschecker_players <- sapply(doubles_split ,function(x){paste(x[2],x[4])})
  }

  if(length(intersect(tolower(oddschecker_players), tolower(betfair_players)))==0)
    return(data.frame(error="Events don't match up- No players in common",
                      bf_players=paste0(betfair_players,collapse=", "),
                      oc_players=paste0(oddschecker_players,collapse=", "))
    )


  players <- betfair_players[partialMatch(tolower(oddschecker_players), tolower(betfair_players))]

  if(sum(is.na(players))==2)
    return(data.frame(error="partialMatch failed on these players",
                      bf_players=paste0(betfair_players,collapse=", "),
                      oc_players=paste0(oddschecker_players,collapse=", "))
    )


  if(sum(is.na(players))==1)
    players[is.na(players)] = betfair_players[!betfair_players %in% players]

  odds <- rvest::html_nodes(scraped_match,".bc .np , .bs") %>% rvest::html_text() %>% sapply(betScrapeR::fracToDec)


  if(length(odds) == 0)
    return(data.frame(error="No odds data scraped. Is that match over?"))

  checker <- as.data.frame(matrix(odds,length(bookies),length(players)))

  colnames(checker) <- players
  rownames(checker) <- bookies

  output <- t(rbind(betfair_prices, checker[,names(betfair_prices)]))

  rownames(output) <- NULL

  if(doubles)
    betfair_players <- gsub(" ", "/", players)

  return(cbind(data.frame(eventId= input$event$id, marketId = betfair_info$marketId,
                          players = betfair_players, selectionId = betfair_info$runners[[1]]$selectionId),
               output)
  )

}

