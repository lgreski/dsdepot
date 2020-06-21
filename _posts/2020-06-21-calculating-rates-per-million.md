---
layout: post
title: Calculating rates per million U.S. State population
tags: R-bloggers dplyr census-data readxl
---


A user on [Stackoverflow](https://stackoverflow.com/questions/62500828/calculating-count-per-1-million-population-of-each-state-using-two-data-source) recently asked about how to convert a data set containing crime statistics (e.g. auto accidents, shootings, etc) into rates per million population by U.S. state.

To calculate crime rates one needs to merge a source of U.S. state level population data with the data frame containing the event by state data. Fortunately, United States taxpayers have paid to have this information collected by funding of the U.S. Census Bureau.

To illustrate this approach one can use the 2019 U.S. population estimates from the U.S. Census Bureau that are included in a data set of [state level population estimates from 2010 - 2019](https://www2.census.gov/programs-surveys/popest/tables/2010-2019/state/totals/nst-est2019-01.xlsx).

The numerators in our rates will be derived from the June 20, 2020 COVID-19 statistics courtesy of our friends at the [Johns Hopkins University Center for Systems Science and Engineering](https://systems.jhu.edu).  

First, we download and load the US population data, which looks like this.

[![enter image description here][1]][1]

    popData <- "https://www2.census.gov/programs-surveys/popest/tables/2010-2019/state/totals/nst-est2019-01.xlsx"

    download.file(popData,
                  "./data/nst-est2019-01.xlsx",mode="wb")

Next we load the `readxl` package, read the population data, assign column names and keep the July 2019 estimate. We use the `range=` argument to skip the first few rows of data that are summary rows for the total U.S. and aggregated regions of states, as well as the last row which contains data for Puerto Rico.

    library(readxl)
    colNames <- c("state","census2010","est_base",paste0("est_",2010:2019))
    usPopEst <- read_excel("./data/nst-est2019-01.xlsx",
                           range="A10:M60",
                           col_names = colNames)[c(1,13)]
    usPopEst$state <- gsub("\\.","",usPopEst$state)

Now, we read the COVID-19 data as of June 20th, 2020 from my forked version of the JHU CCSE COVID-19 Github repository.

    # read covid-19 data for June 20th
    covidFile <- "https://raw.githubusercontent.com/lgreski/COVID-19/master/csse_covid_19_data/csse_covid_19_daily_reports/06-20-2020.csv"
    covidData <- read.csv(covidFile,
                          header=TRUE)

Since the COVID-19 data is at a county / zip code level, we need to aggregate it to the state level. Once aggregated, we merge the confirmed cases and deaths columns with the population estimates and calculate incidence rates per million population. The `dplyr` package provides the R functions we need to group, aggregate, and calculate the desired rates.

    # aggregate stats to state level
    library(dplyr)
    covidData %>% filter(Country_Region == "US") %>%
         rename(state = Province_State) %>%
         group_by(state) %>%
         summarise(Confirmed = sum(Confirmed),
                   Deaths = sum(Deaths)) %>%
         inner_join(.,usPopEst) %>%
         mutate(confirmed_per_million = Confirmed / (est_2019 / 1000000),
                death_per_million = Deaths / (est_2019 / 1000000)) -> summedStates

    head(summedStates)

...and the output:

    > head(summedStates)
    # A tibble: 6 x 6
      state      Confirmed Deaths est_2019 confirmed_per_million death_per_million
      <chr>          <int>  <int>    <dbl>                 <dbl>             <dbl>
    1 Alabama        29549    838  4903185                 6026.             171.
    2 Alaska           741     12   731545                 1013.              16.4
    3 Arizona        50127   1346  7278717                 6887.             185.
    4 Arkansas       15142    224  3017804                 5018.              74.2
    5 California    175213   5494 39512223                 4434.             139.
    6 Colorado       30333   1647  5758736                 5267.             286.
    >


  [1]: https://i.stack.imgur.com/zTjwg.png
