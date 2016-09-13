---
title: "betScrapeR example"
author: "David Sheehan"
date: "2016-09-08"
output: rmarkdown::html_vignette
vignette: >
  %\VignetteIndexEntry{betScrapeR example}
  %\VignetteEngine{knitr::rmarkdown}
  \usepackage[utf8]{inputenc}
---

How to use tennisScraper
=======

This page will describe how to use the `tennisScraper` function. While I'll go through the process in some detail, if you're not familiar with R and/or how to install this package, then consult the more general introductory tutorial [here](https://github.com/dashee87/betScrapeR/blob/master/vignettes/example.Rmd)

## Before We start

I'm going to assume you've installed `betScraper` and the [abettor](https://github.com/phillc73/abettor) package. If so, we start by loading the `betScraper` package.


```r
require("betScrapeR")
```

I'm also going to assume you have a Betfair API key. If not, then read the instructions on the homepage of this package. We'll be calling the Betfair API to find out current back and lay prices for our tennis players. Therefore, we need to ensure we have a valid session token. Let's make sure by logging in.

```r
# logging in
abettor::loginBF("username","password","appkey")
```

If you're not interested in programming and more interested in finding arbs, then you can go straight to the tennis shiny app. Note that it relies on the great `ShinySky` package. So if you haven't yet, you'll need to install it before running app.


```r
# installing ShinySky package
# devtools::install_github("AnalytixWare/ShinySky")
launch("tennis")
```

If run from the console, the recommended way (as it's the most efficient) to use `tennisScraper` is to pass a tennis match data frame. We can do this constructing a data frame of all the tennis matches offered on the Betfair exchange.


```r
# Tennis = 2;
betfair_tennis=abettor::listMarketCatalogue(eventTypeIds = "2", marketTypeCodes = "MATCH_ODDS", 
                                            inPlayOnly = NULL,
                                            marketProjection =c("RUNNER_DESCRIPTION","EVENT"),
                                            fromDate = format(Sys.time()-60*60*24, "%Y-%m-%dT%TZ"),
                                            toDate = format(Sys.time()+60*60*72, "%Y-%m-%dT%TZ"));
```

`betfair_tennis` is a dataframe containg information (start time, player names, etc) related to every upcoming tennis match. If this all looks unfamiliar to you so far, then more details about calling the Betfair API from R can be found on the [abettor](https://github.com/phillc73/abettor) documentation. Let's familiarise ourselves with the structure of `betfair_tennis`:


```r
 head(betfair_tennis)
```

```
##      marketId marketName totalMatched
## 1 1.126707762 Match Odds         0.00
## 2 1.126724393 Match Odds    281136.82
## 3 1.126723799 Match Odds     65414.06
## 4 1.126729835 Match Odds    189017.17
## 5 1.126729746 Match Odds      1087.49
## 6 1.126730149 Match Odds   1548115.71
##                                                                  runners
## 1         11731114, 10483998, Mena/Velotti, Romboli/Zampieri, 0, 0, 1, 2
## 2            8461316, 7287672, Pedro Cachin, Arthur De Greef, 0, 0, 1, 2
## 3  8736474, 8826915, Diego Schwartzman, Juan Sebastian Gomez, 0, 0, 1, 2
## 4     2010693, 9128738, Lopez/Lopez, Carreno Bus/Garcia-Lope, 0, 0, 1, 2
## 5 11731108, 7653428, Hernandez-Fernande/Saez, Escobar/Quiroz, 0, 0, 1, 2
## 6       2538236, 6199453, Serena Williams, Karolina Pliskova, 0, 0, 1, 2
##   event.id                               event.name event.countryCode
## 1 27920386          Mena/Velotti v Romboli/Zampieri                CO
## 2 27921310                        Cachin v De Greef                ES
## 3 27921270                   Schwartzman v Ju Gomez                CO
## 4 27921515    Lopez/Lopez v Carreno Bus/Garcia-Lope                US
## 5 27921505 Hernandez-Fernande/Saez v Escobar/Quiroz                CO
## 6 27921565               Ser Williams v Ka Pliskova                US
##   event.timezone           event.openDate
## 1            UTC 2016-09-08T00:42:00.000Z
## 2            UTC 2016-09-08T20:27:00.000Z
## 3            UTC 2016-09-08T21:28:00.000Z
## 4            UTC 2016-09-08T21:47:00.000Z
## 5            UTC 2016-09-08T22:42:00.000Z
## 6            UTC 2016-09-08T23:00:00.000Z
```

This tutorial was written on 8th September 2016, during the US Open. Novak Djokovic faces Gael Monfils in the Semi Finals tomorrow. So, let's see if we can find arbs for Nole. Or maybe just see what odds we can get on him to make make the final.

Okay, so we have a data frame of all tennis matches on the Betfair exchange. One of these will be the Djokovic v Monfils match. Let's find it.


```r
betfair_tennis[grepl("Djokovic",betfair_tennis$event$name),]
```

```
##       marketId marketName totalMatched
## 55 1.126708112 Match Odds     420091.2
##                                                       runners event.id
## 55 2249229, 2257300, Novak Djokovic, Gael Monfils, 0, 0, 1, 2 27920442
##              event.name event.countryCode event.timezone
## 55 N Djokovic v Monfils                US            UTC
##              event.openDate
## 55 2016-09-09T19:00:00.000Z
```

This contains all the information `tennisScraper` needs to find the corresponding odds offered by bookmakers. We just need to tell it that we've decided to give it a data frame (this will make more sense later).


```r
tennisScraper(type = "df", match = betfair_tennis[grepl("Djokovic",betfair_tennis$event$name),])
```

```
##    eventId    marketId        players selectionId Back Price Back Size
## 1 27920442 1.126708112 Novak Djokovic     2249229       1.15 371898.10
## 2 27920442 1.126708112   Gael Monfils     2257300       7.20    675.84
##   Lay Price Lay Size  Bet 365 Sky Bet Betstars Boylesports Betfred
## 1      1.16  3193.82 1.111111   1.125 1.142857       1.125   1.125
## 2      7.40   895.01 6.500000   6.000 5.750000       6.500   6.000
##   Sportingbet Bet Victor Paddy Power Stan James 888sport Ladbrokes
## 1    1.142857      1.125    1.142857   1.142857 1.142857     1.125
## 2    5.750000      7.000    5.500000   6.000000 6.000000     6.000
##      Coral William Hill Winner Betfair Sportsbook   Betway BetBright
## 1 1.142857     1.142857  1.125           1.142857 1.142857  1.142857
## 2 5.500000     5.500000  6.000           6.500000 5.500000  6.000000
##   Netbet UK   Unibet     Bwin 32Red Bet    10Bet Marathon Bet 188Bet
## 1  1.117647 1.142857 1.117647  1.142857 1.117647     1.157895  1.125
## 2  6.846154 6.000000 6.000000  6.000000 6.846154     6.800000  5.600
##   Black Type  Betfair   Betdaq Matchbook
## 1      1.125 1.142857 1.153846  1.166667
## 2      6.000 6.800000 6.800000  7.000000
```

 
So, the bookies and the exchange agree that Djokovic is the clear favourite. But there's other ways to run `tennisScraper`. Look back at the Djokovic exchange data and you'll see an event Id and market Id (you can also find these ids from exchange urls). Let's pass these ids to `tennisScraper`, though we need to tell it to expect an id.


```r
#event id
 tennisScraper(type = "id", match = "27920442")
```

```
##    eventId    marketId        players selectionId Back Price Back Size
## 1 27920442 1.126708112 Novak Djokovic     2249229       1.15 371898.10
## 2 27920442 1.126708112   Gael Monfils     2257300       7.20    675.84
##   Lay Price Lay Size  Bet 365 Sky Bet Betstars Boylesports Betfred
## 1      1.16  3193.82 1.111111   1.125 1.142857       1.125   1.125
## 2      7.40   895.01 6.500000   6.000 5.750000       6.500   6.000
##   Sportingbet Bet Victor Paddy Power Stan James 888sport Ladbrokes
## 1    1.142857      1.125    1.142857   1.142857 1.142857     1.125
## 2    5.750000      7.000    5.500000   6.000000 6.000000     6.000
##      Coral William Hill Winner Betfair Sportsbook   Betway BetBright
## 1 1.142857     1.142857  1.125           1.142857 1.142857  1.142857
## 2 5.500000     5.500000  6.000           6.500000 5.500000  6.000000
##   Netbet UK   Unibet     Bwin 32Red Bet    10Bet Marathon Bet 188Bet
## 1  1.117647 1.142857 1.117647  1.142857 1.117647     1.157895  1.125
## 2  6.846154 6.000000 6.000000  6.000000 6.846154     6.800000  5.600
##   Black Type  Betfair   Betdaq Matchbook
## 1      1.125 1.142857 1.153846  1.166667
## 2      6.000 6.800000 6.800000  7.000000
```

```r
#market id
 tennisScraper(type = "id", match = "1.126708112")
```

```
##    eventId    marketId        players selectionId Back Price Back Size
## 1 27920442 1.126708112 Novak Djokovic     2249229       1.15 371898.10
## 2 27920442 1.126708112   Gael Monfils     2257300       7.20    675.84
##   Lay Price Lay Size  Bet 365 Sky Bet Betstars Boylesports Betfred
## 1      1.16  3193.82 1.111111   1.125 1.142857       1.125   1.125
## 2      7.40   895.01 6.500000   6.000 5.750000       6.500   6.000
##   Sportingbet Bet Victor Paddy Power Stan James 888sport Ladbrokes
## 1    1.142857      1.125    1.142857   1.142857 1.142857     1.125
## 2    5.750000      7.000    5.500000   6.000000 6.000000     6.000
##      Coral William Hill Winner Betfair Sportsbook   Betway BetBright
## 1 1.142857     1.142857  1.125           1.142857 1.142857  1.142857
## 2 5.500000     5.500000  6.000           6.500000 5.500000  6.000000
##   Netbet UK   Unibet     Bwin 32Red Bet    10Bet Marathon Bet 188Bet
## 1  1.117647 1.142857 1.117647  1.142857 1.117647     1.157895  1.125
## 2  6.846154 6.000000 6.000000  6.000000 6.846154     6.800000  5.600
##   Black Type  Betfair   Betdaq Matchbook
## 1      1.125 1.142857 1.153846  1.166667
## 2      6.000 6.800000 6.800000  7.000000
```

This might all seem very organised. What if I just want to quickly know the odds for Nole's next match? `tennisScrapeR` has got that covered. Just pass the function a string of part of your player's name.


```r
 tennisScraper(type = "name", match = "djokovic")
```

```
##    eventId    marketId        players selectionId Back Price Back Size
## 1 27920442 1.126708112 Novak Djokovic     2249229       1.15 371898.10
## 2 27920442 1.126708112   Gael Monfils     2257300       7.20    675.84
##   Lay Price Lay Size  Bet 365 Sky Bet Betstars Boylesports Betfred
## 1      1.16  3193.82 1.111111   1.125 1.142857       1.125   1.125
## 2      7.40   895.01 6.500000   6.000 5.750000       6.500   6.000
##   Sportingbet Bet Victor Paddy Power Stan James 888sport Ladbrokes
## 1    1.142857      1.125    1.142857   1.142857 1.142857     1.125
## 2    5.750000      7.000    5.500000   6.000000 6.000000     6.000
##      Coral William Hill Winner Betfair Sportsbook   Betway BetBright
## 1 1.142857     1.142857  1.125           1.142857 1.142857  1.142857
## 2 5.500000     5.500000  6.000           6.500000 5.500000  6.000000
##   Netbet UK   Unibet     Bwin 32Red Bet    10Bet Marathon Bet 188Bet
## 1  1.117647 1.142857 1.117647  1.142857 1.117647     1.157895  1.125
## 2  6.846154 6.000000 6.000000  6.000000 6.846154     6.800000  5.600
##   Black Type  Betfair   Betdaq Matchbook
## 1      1.125 1.142857 1.153846  1.166667
## 2      6.000 6.800000 6.800000  7.000000
```

Just beware that with this approach. `tennisScraper` can only handle one match at a time. It will return an error if your name matches more than one event.


```r
 tennisScraper(type = "name", match = "novak")
```

```
##                                                                    error
## 1 Name found in multiple Betfair tennis matches. Please be more specific
##                                                  matches
## 1 Haase/Westerhof v Dzumhur/Novak & N Djokovic v Monfils
```

In fact, an error data frame is returned for a variety of reasons. For example, Ireland's #1 James McGee is not playing this week, so running `tennisScraper` on this occasion will return an error.


```r
 tennisScraper(type = "name", match = "James McGee")
```

```
##                                                 error
## 1 Couldn't find that name in any Betfair tennis match
```



## Summary

So, you've done it. With very little effort, you've combined exchange and bookie data for any tennis match. If you've had any issues/difficulties with this tutorial, then please do let me know [here](https://github.com/dashee87/betScrapeR/issues). Oh, and good luck, Nole!

![winning.jpg](http://images.indianexpress.com/2015/09/novakdjokovicreuters-m1.jpg)
