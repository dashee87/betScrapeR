betScrapeR
=======

`betScrapeR` is an R package that combines exchange data from the Betfair API with web scraped odds from various bookmakers (via odds comparison sites). This information can then inform and improve trading strategies.

As it relies on web scraping, any changes to the scraped websites will invalidate the whole package. If you spot any bugs, then please raise an [issue](https://github.com/dashee87/betScrapeR/issues) or fork it and start a pull request.

[![betScrapeR.gif](https://s10.postimg.org/on0of88o9/bet_Scrape_R.gif)](https://postimg.org/image/i9blbz3s5/)

## Getting Started

### Install

Install from GitLab

```r
# install.packages("devtools")
devtools::install_git("https://gitlab.com/dashee87/betScrapeR.git")
library("betScrapeR")
```
You can install from GitHub (identical mirror of GitLab)

```r
# install.packages("devtools")
devtools::install_github("dashee87/betScrapeR")
library("betScrapeR")
```

Alternatively, you can copy the R files onto your computer and run them all locally (only if the other approaches fail for some reason).

### Required Packages

[abettor](https://github.com/phillc73/abettor) is a package to perform calls on the Betfair exchange via its API. We will use [abettor](https://github.com/phillc73/abettor) to retrieve exchange data. Please consult its extensive documentation, if you want design a trading strategy based on data derived from `betScrapeR`. As [abettor](https://github.com/phillc73/abettor) is not supported by CRAN, you'll need to install it seperately. Similar to before, just install it directly from RStudio:

Install from GitLab

```r
# install.packages("devtools")
devtools::install_git("https://gitlab.com/phillc73/abettor.git")
library("abettor")
```
Or install from GitHub if you prefer (identical mirror of GitLab)

```r
# install.packages("devtools")
devtools::install_github("phillc73/abettor")
library("abettor")
```


This exchange data is combined with the corresponding bookmakers' odds, which are scraped directly from odds comparison websites using [rvest](https://cran.r-project.org/web/packages/rvest/rvest.pdf). [rvest](https://cran.r-project.org/web/packages/rvest/rvest.pdf) works particularly well in combination with [SelectorGadget](https://cran.r-project.org/web/packages/rvest/rvest.pdf), a handy internet browser extension that allows you to easily extract css tags from websites. As it's supported by CRAN, [rvest](https://cran.r-project.org/web/packages/rvest/rvest.pdf) will be automatically installed with `betScrapeR` (if it's not already installed). So it's just [abettor](https://github.com/phillc73/abettor) that you need to install manually.

### Tutorial

I've created a short tutorial on how to install and use `betScrapeR`, including an example showing how `betScrapeR` can be used to identify arbs. The tutorial can be viewed [here](https://github.com/dashee87/betScrapeR/blob/master/vignettes/example.Rmd). A tennis specific tutorial is available [here](https://github.com/dashee87/betScrapeR/blob/master/vignettes/tennis.md).

### Obtain a Betfair Developer Application Key

Only people with betfair application (app) keys will be able to use this package. Therefore, you may need to obtain a developer app key for the Exchange API. Please follow the instructions [here](https://developer.betfair.com/get-started/#exchange-api). If you intend to use this package in a commercial context (e.g. software design), you need to apply for a [Betfair Software Vendor Licence](https://developer.betfair.com/default/api-s-and-services/vendor-program/vendor-program-overview/). Personal use of the `betScrapeR` package will only require an Exchange API app key.

Just note that there are two types of application keys: delayed and live. The former is free but provides limited API functionality. For example, you can't place bets and market data is returned with a 1-60 second delay. In contrast, live app keys allow full functionality (place bets, market data with no delay, etc), but cost £299. I'm not too familiar with the delayed app key, as the live app key was free when I started out. If parts of the package are incomptible with a delayed app key, then please submit an [issue](https://github.com/dashee87/betScrapeR/issues). Please initially test the package with a delayed app key, bearing in mind your calls will be subject to a delay.

## Status

This package is under active development and is currently subject to regular updates.

Currently, the package only supports horse racing (not including races in Australia and New Zealand) and tennis.

### Issues

Web scraping alogirithms are very sensitive to minor website changes (and my code is not immune to more general bugs). Please let me know if something's not working.

[Submit issues here](https://github.com/dashee87/betScrapeR/issues).

### Future

* Complete horse racing functionality
* Tackle football (one country, one league, one market at a time)
* Shiny apps

## Links

* [Betfair Online Betting Exchange](https://www.betfair.com)
* [Betfair Developer Program](https://developer.betfair.com/)
* [Betfair Exchange API Documentation](http://docs.developer.betfair.com/docs/display/1smk3cen4v3lu3yomq5qye0ni)
* [rvest Documentation](https://cran.r-project.org/web/packages/rvest/rvest.pdf)
* [Web Scraping with R tutorials](http://www.r-bloggers.com/search/web%20scraping)

## Disclaimer

The `betScrapeR` package is provided with absolutely no warranty. If you intend to incorporate this package into your trading strategies, please tread carefully. Start with small stakes; a small bug/mistake could lead to big losses.

