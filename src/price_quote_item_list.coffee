#price_quote_item_list.coffee


EventEmitter = require('events').EventEmitter

async = require 'async'


YahooQuotes = require 'yahoo_quotes' 


class PriceQuoteItemList extends EventEmitter

  constructor: (@ticker, @iso_start_date, @iso_end_date) -> 

    self = @

    async.series {

      price_quotes:  (callback) ->
        yq = new YahooQuotes(self.ticker, self.iso_start_date, self.iso_end_date, "prices")
        yq.on 'error', (err) -> callback err
        yq.on 'data', (yahoo_rec_list) -> callback null, yahoo_rec_list

        return


      dividends:  (callback) ->
        yq = new YahooQuotes(self.ticker, self.iso_start_date, self.iso_end_date, "dividends")
        yq.on 'error', (err) -> callback err
        yq.on 'data', (yahoo_rec_list) ->   callback null, yahoo_rec_list



        return

      }
      , (err, results) ->
          if err
            self.emit('error', err, null)

          else if invalid_rec_list_prices(results.price_quotes)
            err = make_error("invalid_price_quotes", "invalid price quotes")
            self.emit('error', err, null)

          else
            pq_item_list  = insert_dividends(results.price_quotes, results.dividends)
            pq_item_list  = insert_splits_returns(pq_item_list)
            pq_item_list.sort (a, b) ->
              if a.iso_date > b.iso_date then 1 else -1

            self.emit('data', null, pq_item_list)

          return


#-------------------------------------------------------

make_error = (err, msg) ->
  e = new Error(msg)
  e.code = err
  return e

isNumber = (n) ->
  return !isNaN(parseFloat(n)) and isFinite(n)

roundNumber = (number, precision) ->
  Number (number).toFixed(precision)


#--------------------------------------------------------

invalid_rec_list_prices = (rec_list_prices) ->
  return true if not rec_list_prices? or rec_list_prices.length == 0 

  price_quote = rec_list_prices[0]

  return true if not price_quote.iso_date

  date_array = price_quote.iso_date.split("-")
  return true if date_array.length != 3

  return true if not price_quote.volume
  return true if not isNumber(price_quote.volume)

  return false


#---------------------------------------------------------

insert_dividends = (rec_list_prices, rec_list_dividends) ->
  return rec_list_prices if rec_list_dividends.length == 0
  dtable = {}
  for d in rec_list_dividends
    dtable[d.iso_date] = d.dividend

  for p in rec_list_prices
    if dtable[p.iso_date]?
      p.dividend = dtable[p.iso_date]

  return rec_list_prices


#---------------------------------------------------------

insert_splits_returns = (pq_item_list) ->
  sr_table = get_splits_returns_table(pq_item_list) 


  for pqi in pq_item_list
    sr = sr_table[pqi.iso_date]
    continue if not sr?

    pqi.percent_return  = sr.percent_return   if sr.percent_return?
    pqi.split   = sr.split    if sr.split?


  return pq_item_list


get_splits_returns_table = (pq_item_list) ->
  sr_table = {}
  o                 = get_tables(pq_item_list)
  dividend_table    = o.dividend_table
  close_price_table = o.close_price_table
  adj_close_table   = o.adj_close_table

  iso_dates_list = (iso_date for iso_date of close_price_table)
  throw new Error("empty iso_dates_list") if iso_dates_list.length == 0

  iso_dates_list.sort()

  id = iso_dates_list.shift()
  prior_adj_close = adj_close_table[id]
  prior_close_price = close_price_table[id]

  for id in iso_dates_list
    dividend = dividend_table[id]
    adj_close = adj_close_table[id]
    close_price = close_price_table[id]
    dividend = 0 if not dividend?

    o = {dividend, adj_close, close_price, prior_adj_close, prior_close_price}

    sr_table[id] = get_split_return(o)

    prior_adj_close = adj_close
    prior_close_price = close_price


  return sr_table

get_tables = (pq_item_list) ->
  close_price_table = {}
  dividend_table = {}
  adj_close_table = {}

  for pqi in pq_item_list       # price_quote_item
    close_price_table[pqi.iso_date] = pqi.close_price
    adj_close_table[pqi.iso_date]   = pqi.adj_close
    dividend_table[pqi.iso_date]    = pqi.dividend if pqi.dividend?

  o = {close_price_table, dividend_table, adj_close_table}

  return o

get_split_return = (o) ->
  if (o.prior_adj_close <= 0) or (o.prior_close_price <= 0)
    return {split: null, return: null}

  percent_return = ( (o.adj_close / o.prior_adj_close) - 1.0 ) * 100.0


  percent_return_in_theory = ( ( (o.close_price + o.dividend) / o.prior_close_price ) - 1.0 ) * 100.0

  diff = Math.abs(percent_return - percent_return_in_theory)

  split = if diff > 0.02 then get_split(o) else null


  percent_return = roundNumber(percent_return, 4)

  return {split, percent_return}

get_split = (o) ->
  split = (o.prior_close_price * o.adj_close / o.prior_adj_close) - (o.close_price + o.dividend)
  return roundNumber(split,2)


module.exports = PriceQuoteItemList




