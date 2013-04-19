#!/usr/bin/env coffee

require 'colors'
{Weathernaut} = require '../'

usage = "#{'$'.white.bold} #{'weathernaut'.red} [options]"

argv = require('optimist')
          .alias('s', 'service').describe('s', "The Weather Underground service to query (#{Weathernaut.validServices().join('|')})")
          .alias('z', 'zip').describe('z', 'The zipcode you want your query to target.')
          .alias('k', 'apikey').describe('k', 'Weather Underground API key.')
          .alias('d', 'days').describe('d', 'Number of days (only has an effect with the "forecast" service).').default('d', 10)
          .usage("Usage:\n  #{usage}")
          .demand(['s', 'z', 'k'])
          .argv

{service, zip, apiKey, days} = argv

naut = new Weathernaut apiKey

switch service
    when 'astronomy' then naut.printAstronomicalDataFor  zip
    when 'forecast'
        naut.printForecastDataFor(zip, days)
    else
        console.error "Valid values for the 'service' argument are: #{Weathernaut.validServices().join(', ')}"

