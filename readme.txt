readme.txt

Async PriceQuoteItemList

Class can be used to create an object that can be used to download a
list of daily price quote objects. 

Each object in the list has the following attributes:

iso_date: String in iso format - i.e. yyyy-mm-dd

open_price: Number

high_price: Number

low_price:  Number

close_price:  Number 

volume: Number representing the number of shares traded.

adj_close: Number that is the closing price adjusted for splits and dividends.

dividend: Number that is the dividend on that day (may be undefined).

split: 
  Number that represents the value of a stock split on that day (may be undefined).
  Split can be used to calculate the adjusted close for a given day.

percent_return: 
  Number that is a percent return (not log_return) for the past day.

  It is calculated using the adj_close from the previous day and the
  adj_close from the current day. 

  The precent_return for the first day  in the list will be undefined

  It's better to store percent returns because we can represent
  a 100% loss with percent returns.


Example of usage:

PriceQuoteItemList             = require 'price_quote_item_list'
ticker = 'ibm'
iso_start_date = "2012-12-31"
iso_end_date   = "2013-12-31"
pdq = new PriceQuoteItemList(ticker, iso_start_date, iso_end_date)
pdq.on 'error', (err, pq_item_list) -> throw err
pdq.on 'data', (err, pq_item_list) ->
  n = 30
  console.log "#{ticker} price quotes #{n} days"
  cnt = 0
  for q in pq_item_list
    cnt += 1
    break if cnt > n
    console.log("%s,%s,%s,%s", q.iso_date, q.close_price, q.adj_close, q.percent_return)