
require 'colors'
request = require 'request'
fs      = require 'fs'
path    = require 'path'
async   = require 'async'


#
# this error handling mechanism is a piece of shit
#
handleError = (func, err) ->
    console.error "Error in #{func}: #{err.toString().red}"
    process.exit(1)


class WeathernautStore
    apiKey:    null
    cacheFile: null
    cache:     null
    maxCacheAgeInMsec: null

    constructor: (@apiKey) ->
        @cacheFile         = path.join(process.env.HOME, '.weathernaut-cache')
        @maxCacheAgeInMsec = 1000 * 60 * 60 * 12   # 12 hours
        @cache = @readCacheFile()

    readCacheFile: () =>
        # ensure cache file exists
        unless fs.existsSync(@cacheFile) then fs.writeFileSync @cacheFile, JSON.stringify {}

        # read into memory
        try JSON.parse(fs.readFileSync(@cacheFile).toString())
        catch err
            {}

    cachedDataExistsFor:     (service, zipcode) => @cache?[ service ]?[ zipcode ]?
    cachedDataIsNotStaleFor: (service, zipcode) => (new Date().getTime() - @cache?[ service ]?[ zipcode ]?.retrievedOn) < @maxCacheAgeInMsec
    cachedDataIsValidFor:    (service, zipcode) => @cachedDataExistsFor(service, zipcode) and @cachedDataIsNotStaleFor(service, zipcode)

    doAPIRequest: (service, zipcode, callback) =>
        url = "http://api.wunderground.com/api/#{@apiKey}/#{service}/q/#{zipcode}.json"

        request url, (err, response, body) =>
            if err? then handleError 'doAPIRequest', err

            if response?.statusCode isnt 200
                handleError 'doAPIRequest', "http status code was #{response?.statusCode?.toString().yellow}"

            try
                responseObj = JSON.parse body?.toString?()
                if responseObj?.response?.error?
                    throw new Error(responseObj.response.error.type)

                responseObj.retrievedOn = new Date().getTime()
                delete responseObj.response

                callback null, responseObj

            catch err
                callback err

    writeMemoryCacheToDisk: (callback) =>
        try
            fs.writeFileSync(@cacheFile, JSON.stringify @cache)
            callback()
        catch err
            handleError 'writeMemoryCacheToDisk', err
            callback err

    updateCacheFor: (service, zipcode, callback) =>
        @doAPIRequest service, zipcode, (err, dataForZip) =>
            if err? then return callback(err)

            @cache[ service ] ?= {}
            @cache[ service ][ zipcode ] = dataForZip
            @writeMemoryCacheToDisk (err) =>
                if err then handleError 'updateCacheFor', err
                callback()



    getDataFor: (service, zipcode, callback) =>
        if @cachedDataIsValidFor service, zipcode
            callback null, @cache[ service ][ zipcode ]

        else
            @updateCacheFor service, zipcode, (err) =>
                if err then handleError 'getDataFor', err
                callback err,  @cache[ service ][ zipcode ]



class WeathernautDefaultFormatter
    constructor: () ->

    printAstronomicalData: (zip, data) =>
        try
            {moon_phase} = data
            {percentIlluminated, sunrise, sunset} = moon_phase

            lines = [
                { label: 'moon:    ', data: "#{percentIlluminated?.toString?()}% full" }
                { label: 'sunrise: ', data: "#{sunrise?.hour?.toString?()}:#{sunrise?.minute?.toString?()}" }
                { label: 'sunset:  ', data: "#{sunset?.hour?.toString?()}:#{sunset?.minute?.toString()}" }
            ]

            header         = @formatAstronomicalHeader zip
            formattedLines = (@formatAstronomicalLine(line) for line in lines)

            console.log header
            console.log formattedLines.join '\n'

        catch err
            handleError 'WeathernautDefaultFormatter::printAstronomicalData', err

    formatAstronomicalHeader: (zipcode) => '***'.white.bold + " astronomy for #{zipcode} ".red.bold + '***'.white.bold
    formatAstronomicalLine:   (line)    => ' --> '.white.bold + line.label.toString().red + ' ' + line.data.toString().white


    printForecastData: (zip, data, maxDays = 10) =>
        try
            header            = @formatForecastHeader zip, maxDays
            formattedDays     = (@formatForecastDay(day) for day in data.forecast.simpleforecast.forecastday.splice(0, maxDays))
            spacesBetweenDays = 4
            spacesBetweenDays = Array(spacesBetweenDays + 1).join ' '
            highs = (day.high for day in formattedDays).join spacesBetweenDays
            lows  = (day.low  for day in formattedDays).join spacesBetweenDays

            console.log [ header, highs, lows ].join '\n'

        catch err
            handleError 'WeathernautDefaultFormatter::printForecastData', err


    formatForecastHeader: (zip, maxDays) => '***'.white.bold + " #{maxDays}-day forecast for #{zip} ".red.bold + '***'.white.bold

    formatForecastDay: (day) =>
        low            = day.low.fahrenheit.toString()
        high           = day.high.fahrenheit.toString()
        dateNumInner   = "#{day.date.month}/#{day.date.day}"
        dateNum        = "(#{dateNumInner}) "
        dateNumColored = "(#{dateNumInner.cyan}) "
        dateWeekday    = "#{day.date.weekday_short}: "

        length     = [ dateWeekday.length, "(#{dateNumInner}) ".length ]
        padding    = [0, 0]
        padding[0] = if length[0] < length[1] then length[1] - length[0] else 0
        padding[1] = if length[0] > length[1] then length[0] - length[1] else 0

        padding[0] = Array(padding[0] + 1).join(' ')
        padding[1] = Array(padding[1] + 1).join(' ')

        return {
            high: "#{dateWeekday}#{padding[0]}#{high.red}F",
            low:  "#{dateNumColored}#{padding[1]}#{low.blue.bold}F"
        }



class exports.Weathernaut
    apiKey:  null
    store:   null
    formatter: null

    constructor: (@apiKey) ->
        @store = new WeathernautStore(@apiKey)
        @formatter = new WeathernautDefaultFormatter()

    @VALID_SERVICES:
        astronomy: 'astronomy'
        forecast:  'forecast10day'

    @validServices: () => Object.keys @VALID_SERVICES

    printAstronomicalDataFor: (zipcode) =>
        @store.getDataFor Weathernaut.VALID_SERVICES.astronomy, zipcode, (err, data) =>
            if err? then handleError 'Weathernaut::printAstronomicalDataFor', err
            else
                @formatter.printAstronomicalData zipcode, data

    printForecastDataFor: (zipcode, maxDays) =>
        @store.getDataFor Weathernaut.VALID_SERVICES.forecast, zipcode, (err, data) =>
            if err? then handleError 'Weathernaut::printForecastDataFor', err
            else
                @formatter.printForecastData zipcode, data, maxDays








