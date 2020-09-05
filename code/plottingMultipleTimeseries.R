#
#
# code for blog post 2020-09-05-Plotting-multiple-timeseries.md


library(quantmod)
library(TSclust)
library(ggplot2)
# download financial data

symbols = c('ASX', 'AZN', 'BP', 'AAPL')
start = as.Date("2014-01-01")
until = as.Date("2014-12-31")

stocks = lapply(symbols, function(symbol) {
  adjust = getSymbols(symbol,src='yahoo', from = start, to = until, auto.assign = FALSE)[, 6]
  names(adjust) = symbol
  adjust
})

qplot(symbols, value, data = as.data.frame(stocks), geom = "line", group = variable) +
  facet_grid(variable ~ ., scale = "free_y")

## Base R solution

stocks = lapply(symbols, function(symbol) {
  aStock = as.data.frame(getSymbols(symbol,src='yahoo', from = start, to = until, 
                                    auto.assign = FALSE))
  colnames(aStock) <- c("Open","High","Low","Close","Volume","Adjusted")
  aStock$Symbol <- symbol
  aStock$Date <- as.Date(rownames(aStock),"%Y-%m-%d")
  aStock
})
stocksDf <- do.call(rbind,stocks)
library(ggeasy)
qplot(Date, Adjusted, data = stocksDf, geom = "line", group = Symbol) +
  facet_grid(Symbol ~ ., scale = "free_y") +
  scale_x_date(date_breaks = "14 days") +
  easy_rotate_x_labels(angle = 45, side = "right")

## Joshua Ulrich answer

library(quantmod)
library(ggplot2)

symbols <- c("ASX", "AZN", "BP", "AAPL")
start <- as.Date("2014-01-01")
until <- as.Date("2014-12-31")

# import data into an environment
e <- new.env()
getSymbols(symbols, src = "yahoo", from = start, to = until, env = e)

# extract the adjusted close and merge into one xts object
stocks <- do.call(merge, lapply(e, Ad))

# Remove the ".Adjusted" suffix from each symbol column name
colnames(stocks) <- gsub(".Adjusted", "", colnames(stocks), fixed = TRUE)

# convert the xts object to a long data frame
stocks_df <- fortify(stocks, melt = TRUE)

head(stocks_df)

# plot the data
qplot(Index, Value, data = stocks_df, geom = "line", group = Series) +
  facet_grid(Series ~ ., scale = "free_y")

# use broom to tidy the data
stocks <- do.call(merge, lapply(e, Ad))
head(stocks)
library(broom)
a_tibble <- tidy.zoo(stocks)
head(a_tibble)
