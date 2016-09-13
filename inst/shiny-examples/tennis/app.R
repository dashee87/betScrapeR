# First we check that the necessary packages are installed

req.packages=c("shinydashboard","abettor","rvest","betScrapeR","DT","shinysky")
if(any(! req.packages  %in% installed.packages()))
  stop(paste0("Not all dependent packages are installed on your computer.\n Please install: ",
              paste(req.packages[!req.packages %in% installed.packages()],collapse=","),
              ". See betScrapeR documentation on github for more information on how to install R packages."))

# Next we load these packages

require(shinydashboard)
require(abettor)
require(rvest)
require(betScrapeR)
require(DT)
require(shinysky)

# To speed things up, we retrieve all the Oddschecker links on starting the app
# This removes the need to scrape Oddschecker for links for every event
# It should be safe enough, it's highly unlikely any new links will be added (or old
# links taken down), while the app is running


page <- "http://www.oddschecker.com/tennis/match-coupon"
scraped <- betScrapeR::scrapePage(page, 5, 1)

if(is.data.frame(scraped))
  stop("App wasn't able to scrape Oddschecker links. Restart the app!!!")

links <- rvest::html_nodes(scraped, "a") %>% rvest::html_attr("href")
links <- links[!grepl("://www.", links)]


# betfair_tennis is a dataframe of all tennis events listed on the Betfair exchange
# It will be filtered using user-selected parameters (competition, player name, etc)

betfair_tennis <- abettor::listMarketCatalogue(eventTypeIds = "2", marketTypeCodes = "MATCH_ODDS",
                                                       marketProjection = c("RUNNER_DESCRIPTION","EVENT","COMPETITION",
                                                                  "EVENT_TYPE","MARKET_START_TIME","MARKET_DESCRIPTION"),
                                                       fromDate = format(Sys.time() - 60*60*24, "%Y-%m-%dT%TZ"),
                                                       toDate = format(Sys.time() + 60*60*72, "%Y-%m-%dT%TZ"))

betfair_tennis_inplays <- abettor::listMarketCatalogue(eventTypeIds = "2", marketTypeCodes = "MATCH_ODDS",
                                                       marketProjection = c("RUNNER_DESCRIPTION","EVENT","COMPETITION",
                                                            "EVENT_TYPE","MARKET_START_TIME","MARKET_DESCRIPTION"),
                                                       inPlayOnly = TRUE,
                                                       fromDate = format(Sys.time() - 60*60*24, "%Y-%m-%dT%TZ"),
                                                       toDate = format(Sys.time() + 60*60*72, "%Y-%m-%dT%TZ"))

if(nrow(betfair_tennis)==0){
  stop("No tennis matches retrieved. Did you login? Maybe your session token has expired.")
}

betfair_tennis$inplay <- FALSE
betfair_tennis[betfair_tennis$marketId %in% betfair_tennis_inplays$marketId,]$inplay <- TRUE

# some ugly stuff to correct for British Summer Time (well, I do enjoy later sunsets...)
betfair_tennis$marketStartTimeUTC <- as.POSIXct(betfair_tennis$marketStartTime,format="%Y-%m-%dT%H:%M","Europe/London")
betfair_tennis$marketStartTimeUTC <- betfair_tennis$marketStartTimeUTC +
                                        60*60*(format(betfair_tennis$marketStartTimeUTC,format="%Z")=="BST")
betfair_tennis$marketStartDate <- as.Date(betfair_tennis$marketStartTimeUTC)


# Start of the app now. The rest of the code is essentially construction of
# a shiny app, so I won't comment any further. There's plenty of shiny resources
# on the internet. There's nothing particularly fancy in here, so you should be
# able to understand/tweak/imrpove this app with only minimal shiny knowledge.
#
# As always, if you spot a bug, then please raise it as an issue on the
# betScrapeR github page. Alternatively, if you're a css/html/javascript expert
# and are offended by its aesthetic minimalism, send me a pull request.


ui <- dashboardPage(
  dashboardHeader(title = "betScrapeR"),
  dashboardSidebar(
    radioButtons("match_type",
                 label="Inplay or Preplay?",
                 choices=list("Both"="both", "Inplay Only"="inplay", "Pre Play Only"="preplay"),
                 selected="both"),
    checkboxInput("doubles", "Remove Doubles Matches?", value = FALSE),
    uiOutput("Box1"),
  #  textInput("player", label="Player Name", value = "", placeholder = "e.g. djokovic"),
    uiOutput("Box2"),
    checkboxInput('back', 'Include Back Data?', value = FALSE),
    column(6, align="center", offset = 3,
           shiny::actionButton("goButton", "Run", icon("play"),
                        style="color: #fff; background-color: #337ab7; border-color: #2e6da4"))


  ),
  dashboardBody(
    DT::dataTableOutput("view")
  )
)

server <- function(input, output) {

  filtered_tennis = eventReactive(input$match_type,

    switch(input$match_type,
           "inplay" = betfair_tennis[betfair_tennis$inplay,],
           "preplay" = betfair_tennis[!betfair_tennis$inplay,],
            betfair_tennis)
  )



  output$Box1 <- renderUI({
    tennis_matches <- filtered_tennis()
    if(input$doubles)
      tennis_matches <- tennis_matches[!grepl("/", tennis_matches$event$name),]
    filtered_comps <- unique(tennis_matches$competition$name)
    filtered_comps <- filtered_comps[!is.na(filtered_comps)]
    if(length(filtered_comps)==0)
      return(p("No Competitions. Change Parameters!"))
    filtered_comps <- filtered_comps[order(filtered_comps)]
    checkboxGroupInput("comps", "Select competitions:",
                       filtered_comps,
                       filtered_comps)
  })

  output$Box2 <- renderUI({
    if(is.null(input$comps))
      return()
    tennis_matches <- filtered_tennis()[filtered_tennis()$competition$name %in% isolate(input$comps),]
    if(isolate(input$doubles))
      tennis_matches <- tennis_matches[!grepl("/", tennis_matches$event$name),]

    select2Input("player","Player Name",
                 choices=unique(unlist(lapply(tennis_matches$runners,function(x){x[,"runnerName"]}))),
                 type = "input")
  })

  subdata <- eventReactive(input$goButton, {

    validate(
      need(!is.null(input$comps), 'Select a competition')
    )
    tennis.data <- isolate(filtered_tennis())
    if(isolate(input$doubles))
      tennis.data = tennis.data[!grepl("/", tennis.data$event$name),]
    tennis.data <- tennis.data[tennis.data$competition$name %in% isolate(input$comps),]

    if(length(input$player) > 0){
      all_players <- unlist(lapply(tennis.data$runners,function(x){x[,"runnerName"]}))

      name_matches <- which(all_players %in% input$player)

      validate(
        need(length(name_matches)>0, 'No players found. Change your parameters.')
      )

      tennis.data <- tennis.data[unique(ceiling(name_matches/2)),]
    }

    withProgress(message = 'tennisScrapeR in progress...', {
      tennis.data <- lapply(1:nrow(tennis.data),function(xx){cbind(data.frame(comp=tennis.data[xx,]$competition$name,
                                                                              event=tennis.data[xx,]$event$name,
                                                                              start=tennis.data[xx,]$marketStartTimeUTC,
                                                                              inplay=tennis.data[xx,]$inplay),
                                                                   tennisScraper("df",tennis.data[xx,],tennis_links = links))})
                            })
    tennis.data <- tennis.data[sapply(tennis.data,length)>10]
    validate(
      need(length(tennis.data)>0, 'No data scraped for that parameter selection. Change some of the options.')
    )

    tennis.data <- lapply(tennis.data,function(xy){lapply(1:nrow(xy),function(ab){col.names=colnames(xy)[13:(length(xy))];
    cbind(xy[rep(ab, length(col.names)),c(7,2,1,3,4,9:12)],
          data.frame(bookie=col.names,odds=as.numeric(xy[ab,13:(length(xy))])))})})

    tennis.data <- do.call(rbind,lapply(tennis.data,function(t){do.call(rbind,t)}))
    rownames(tennis.data) <- NULL
    tennis.data$rating <- round(100*(tennis.data$odds/tennis.data$`Lay Price`),2)

    tennis.data[sapply(tennis.data, is.character)] <- lapply(tennis.data[sapply(tennis.data, is.character)],
                                                           as.factor)
    if(any(tennis.data$odds<1|is.na(tennis.data$`Lay Price`))){
      tennis.data[tennis.data$odds<1|is.na(tennis.data$`Lay Price`),]$rating <- 0}

    tennis.data
  })



  output$view <- DT::renderDataTable({
    if(input$back){
      DT::datatable(subdata(),filter="top",rownames=FALSE, options = list(order = list(11,'desc')))
    }else{DT::datatable(subdata()[!colnames(subdata()) %in% c("Back Price","Back Size")]
                        ,filter="top",rownames=FALSE, options = list(order = list(9,'desc')))}
  })
}

shinyApp(ui, server)
