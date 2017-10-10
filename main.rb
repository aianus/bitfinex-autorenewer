#!/usr/bin/env ruby
require 'bundler/setup'
require 'dotenv'
Dotenv.load
require 'pry'
require 'bitfinex'
require 'bigdecimal'

CURRENCY = (ENV['CURRENCY'] || 'usd').downcase
OFFER_DURATION = (ENV['OFFER_DURATION'] || '2').to_i
POLLING_INTERVAL = (ENV['POLLING_INTERVAL'] || '120').to_i

Bitfinex::Client.configure do |conf|
  conf.secret = ENV["BFX_API_SECRET"]
  conf.api_key = ENV["BFX_API_KEY"]
end
client = Bitfinex::Client.new

# Cancel unfilled offers
client.offers.each do |offer|
  client.cancel_offer(offer['id'])
end

# Wait for eventual consistency
sleep 2

available_deposit_balances = Hash[*
  client
    .balances
    .select{|b| b['type'] == 'deposit'}
    .flat_map{|b| [b['currency'], b['available']]}
]

available_deposit_balance = available_deposit_balances[CURRENCY]

puts "Available balance of #{CURRENCY.upcase}#{available_deposit_balance} found"

# Get the edge of the order book
best_ask = BigDecimal.new(client.funding_book(CURRENCY, limit_bids: 1, limit_asks: 1)['asks'][0]['rate'])
our_ask  = best_ask - BigDecimal('0.1')
# Place an offer for all of our money
begin
  client.new_offer(
    CURRENCY,
    available_deposit_balance,
    our_ask.to_s('F'),
    OFFER_DURATION,
    'lend'
  )
  puts "Placed offer for #{CURRENCY.upcase}#{available_deposit_balance} at #{our_ask.to_s('F')}% per year"
rescue Bitfinex::BadRequestError => e
  # Super janky but it's not worth it to figure this out ourselves
  if !(e.message.include?('minimum is 50 dollar') || e.message.include?('must be positive'))
    raise e
  end
end
