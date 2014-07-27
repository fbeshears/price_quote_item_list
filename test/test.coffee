#test.coffee


PriceQuoteItemList             = require '../lib/price_quote_item_list'

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

