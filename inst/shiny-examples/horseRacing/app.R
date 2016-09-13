# First we check that the necessary packages are installed

req.packages=c("shinydashboard","abettor","rvest","betScrapeR","DT")
if(any(! req.packages  %in% installed.packages()))
  stop(paste0("Not all dependent packages are installed on your computer.\n Please install: ",paste(req.packages[!req.packages %in% installed.packages()],collapse=","),". See betScrapeR documentation on github for more information on how to install R packages."))

# Next we load these packages

require(shinydashboard)
require(abettor)
require(rvest)
require(betScrapeR)
require(DT)


present <- as.Date(format(as.POSIXct(Sys.time(),format="%Y-%m-%dT%H:%M","UTC"),tz="Europe/London"))

# HRaces is a dataframe of all horse racing events listed on the Betfair exchange
# It will be filtered using user-selected parameters (race day, country, meeting, etc)

HRaces <- listMarketCatalogue(eventTypeIds = c("7"),
                              fromDate = (format(Sys.time()-60*60, "%Y-%m-%dT%TZ")),
                              toDate = (format(Sys.time()+600000*60, "%Y-%m-%dT%TZ")),
                              marketTypeCodes = c("WIN"))
if(nrow(HRaces)==0){
  stop("No horse races retrieved. Did you login? Maybe your session token has expired.")
}
# some ugly stuff to correct for British Summer Time (well, I do enjoy later sunsets...)
HRaces$marketStartTimeUTC <- as.POSIXct(HRaces$marketStartTime,format="%Y-%m-%dT%H:%M","Europe/London")
HRaces$marketStartTimeUTC <- HRaces$marketStartTimeUTC+ 60*60*(format(HRaces$marketStartTimeUTC,format="%Z")=="BST")
HRaces$marketStartDate <- as.Date(HRaces$marketStartTimeUTC)
HRaces$venuetime <- paste(HRaces$event$venue,substring(HRaces$marketStartTimeUTC,12,16))
event.countries <- HRaces$event$countryCode

# This app utilises one custom function called dateData:
# It's nothing special. It's just way to filter by date, which
# is needed for radio buttons.

dateData <- function(set,toggle){
if(toggle=="Today"){
  return(set[set$marketStartDate==(Sys.Date()),])
}else if(toggle=="Tomorrow"){
  return(set[set$marketStartDate==(Sys.Date()+1),])
}else if(toggle=="Today & Tomorrow"){
  return(set[set$marketStartDate<=(Sys.Date()+1),])
}else{return(set)}
}

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
  radioButtons("rd",
             label="Select the racing days you want to check",
             choices=list("Today","Tomorrow","Today & Tomorrow","All"),
             selected="Today"),
  uiOutput("Box1"),
  uiOutput("Box2"),
  uiOutput("Box3"),
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

  event.countries <- eventReactive(input$rd, {
    event.countries <- unique(dateData(HRaces,input$rd)$event$countryCode)
    if(length(event.countries)==0){
      NULL
    }else if(any(c("IE","GB") %in% event.countries)){
      c("GB & IE","All",event.countries)
    }else{c("All",event.countries)}

  })

  output$Box1 <- renderUI(
    if(is.null(event.countries())){
    p(paste0("No horse races ",input$rd,". Change the time period."))
      }else{selectInput("country","Select a country/region:",event.countries())}
  )

  output$Box2 <- renderUI(
    if (is.null(input$country) || input$country == "All" || is.null(event.countries())){return()
    }
    else if (input$country=="GB & IE"){
      selectInput("meeting",
                  "Select a Meeting",
                  c(unique(dateData(HRaces,input$rd)$event$venue[which(dateData(HRaces,input$rd)$event$countryCode %in% c("GB","IE"))]),"All"),
                  "All")
    }else if (input$country=="All"){
      selectInput("meeting",
                  "Select a Meeting",
                  c(unique(dateData(HRaces,input$rd)$event$venue),"All"),
                  "All")
    }else{selectInput("meeting",
                      "Select a Meeting",
                      c(unique(dateData(HRaces,input$rd)$event$venue[which(dateData(HRaces,input$rd)$event$countryCode ==input$country)]),"All"),
                      "All")}
  )

output$Box3 <- renderUI(
    if (is.null(input$country) || is.null(input$meeting) ||  input$country == "All" ||  length(event.countries()) == 0){return()
    }
    else if (input$country=="GB & IE" & input$meeting== "All"){
      selectInput("race",
                  "Select a Race",
                  c(unique(dateData(HRaces,input$rd)[dateData(HRaces,input$rd)$event$countryCode %in% c("GB","IE"),]$venuetime),"All"),
                  "All")
    }else if (input$meeting== "All"){
        selectInput("race",
                    "Select a Race",
                    c(unique(dateData(HRaces,input$rd)[dateData(HRaces,input$rd)$event$countryCode==input$country,]$venuetime),"All"),
                    "All")
    }else{
        selectInput("race",
                    "Select a Race",
                    c(unique(dateData(HRaces,input$rd)[dateData(HRaces,input$rd)$event$venue==input$meeting,]$venuetime),"All"),
                    "All")}
  )

  subdata <- eventReactive(input$goButton, {
    validate(
      need(!is.null(input$country), 'Select a country/region')
    )
    race.data <- dateData(HRaces,input$rd)
    if(input$country!="All"){
      if(input$country=="GB & IE"){
        race.data=race.data[race.data$event$countryCode %in% c("GB","IE"),]
      }else{race.data=race.data[race.data$event$countryCode == input$country,]}

      if(input$race!="All" & !is.null(input$race)){
        race.data <- race.data[race.data$venuetime==input$race,]
      }else if(input$meeting !="All" & !is.null(input$meeting)){
        race.data <- race.data[race.data$event$venue== input$meeting,]
      }
    }
    withProgress(message = 'horseScrapeR in progress...', {
    race.data <- lapply(1:nrow(race.data),function(xx)cbind(data.frame(race=paste(race.data[xx,]$event$name,substring(race.data[xx,]$marketStartTimeUTC,12,16))),t(horseScraper(race.data[xx,]))));
    })
    race.data <- race.data[sapply(race.data,length)>2]
    validate(
      need(length(race.data)>0, 'No data scraped for that parameter selection. Change some of the options.')
    )
    race.data <- lapply(race.data,function(x){cbind(x,data.frame(horse=rownames(x)))})
    race.data <- lapply(race.data,function(xy){lapply(1:nrow(xy),function(ab){col.names=colnames(xy)[7:(length(xy)-1)];
    cbind(xy[rep(ab, length(col.names)),c(length(xy),1,3:6)],data.frame(bookie=col.names,odds=as.numeric(xy[ab,7:(length(xy)-1)])))})})
    race.data <- do.call(rbind,lapply(race.data,function(t){do.call(rbind,t)}))
    rownames(race.data) <- NULL
    race.data$rating <- round(100*(race.data$odds/race.data$`Lay Price`),2)
    race.data$horse <- as.factor(race.data$horse)
    race.data$bookie <- as.factor(race.data$bookie)
    race.data$race <- as.factor(race.data$race)
    if(any(race.data$odds<1|is.na(race.data$`Lay Price`))){
      race.data[race.data$odds<1|is.na(race.data$`Lay Price`),]$rating <- 0}
    race.data
  })



  output$view <- DT::renderDataTable({
     if(input$back){
       DT::datatable(subdata()[c("horse","race","Back Price","Back Size","Lay Price","Lay Size","bookie","odds","rating")],filter="top",rownames=FALSE, options = list(order = list(8,'desc')))
     }else{DT::datatable(subdata()[c("horse","race","Lay Price","Lay Size","bookie","odds","rating")]
                         ,filter="top",rownames=FALSE, options = list(order = list(6,'desc')))}
  })
}

shinyApp(ui, server)
