fs = require 'fs'
path = require 'path'

require 'colors'
{Weathernaut} = require '../'

usage = "#{'$'.white.bold} #{'weathernaut'.red} [options]"

argv = require('optimist')
          .alias('z', 'zip').describe('z', 'The zipcode you want your query to target.')
          .alias('d', 'days').describe('d', 'Number of days (only has an effect with the "forecast" service).').default('d', 10)
          .alias('a', 'astronomy').describe('a', 'Display astronomical data.').boolean('a')    #"The Weather Underground service to query (#{Weathernaut.validServices().join('|')})")
          .alias('w', 'weather').describe('w', 'Display a weather forecast.').boolean('w')
          .usage("Usage:\n  #{usage}")
          .argv
          # .demand(['s', 'z', 'k'])



configFilepath = path.join(process.env['HOME'], '.weathernaut')

if !fs.existsSync(configFilepath)
    fs.writeFileSync(configFilepath, '{}')

configJson = fs.readFileSync(configFilepath).toString()
config = JSON.parse(configJson)

apiKey  = argv.apiKey  ? config.apiKey
zip     = argv.zip     ? config.zip
days    = argv.days    ? config.days
astronomy = argv.astronomy ? config.astronomy ? false
weather = argv.weather ? config.weather ? false


unless apiKey? and zip? and (astronomy? or weather?) and days?
    console.error "Missing config/argument value.  Expecting 'apiKey', 'zip', 'days', and either 'astronomy' and/or 'weather'."
    process.exit(1)



whetherNot = new Weathernaut(apiKey)

if astronomy
    process.stdout.write('\n')
    whetherNot.printAstronomicalDataFor(zip)
if weather
    process.stdout.write('\n')
    whetherNot.printForecastDataFor(zip, days)

process.stdout.write('\n')

# else
#     console.error "Valid values for the 'service' argument are: #{Weathernaut.validServices().join(', ')}"

