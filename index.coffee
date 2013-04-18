
require 'colors'
request = require 'request'
fs      = require 'fs'
path    = require 'path'
async   = require 'async'
url    = "http://api.wunderground.com/api/#{apiKey}/astronomy/q/#{zip}.json"
cacheFile = path.join(process.env.HOME, '.weathernaut')
cache = {}

maxCacheAgeInMsec = 1000 * 60 * 60 * 12   # 12 hours

handleError = (func, err) ->
    console.error "Error in #{func}: #{err.toString().red}"
    process.exit(1)


ensureCacheFileExists = () ->
    if not fs.existsSync(cacheFile)
        fs.writeFileSync(cacheFile, JSON.stringify {})

readExistingCache = () ->
    ensureCacheFileExists()
    cache =
        try JSON.parse(fs.readFileSync(cacheFile).toString())
        catch err
            {}

cachedDataExistsFor     = (zipcode) -> cache?[ zipcode ]?
cachedDataIsNotStaleFor = (zipcode) -> (new Date().getTime() - cache?[ zipcode ]?.retrievedOn) < maxCacheAgeInMsec
cachedDataIsValidFor    = (zipcode) -> cachedDataExistsFor(zipcode) and cachedDataIsNotStaleFor(zipcode)

doAPIRequest = (zipcode, callback) ->
    request url, (err, response, body) ->
        if err? then handleError 'ensureCacheIsFilled', err

        if response?.statusCode isnt 200
            handleError 'ensureCacheIsFilled', "http status code was #{response?.statusCode?.toString().yellow}"

        body = body?.toString?()
        bodyObject = JSON.parse(body)
        delete bodyObject.response
        bodyObject.retrievedOn = new Date().getTime()

        callback null, bodyObject

writeMemoryCacheToDisk = () ->
    try fs.writeFileSync(cacheFile, JSON.stringify cache)
    catch err
        handleError 'ensureCacheIsFilled', err
                

updateCacheFor = (zipcode, callback) ->
    doAPIRequest zipcode, (err, dataForZip) ->
        if err? then return callback(err)

        cache[ zipcode ] = dataForZip
        writeMemoryCacheToDisk()
        callback()
        
getDataFor = (zipcode, callback) ->
    ensureCacheFileExists()
    readExistingCache()
    if cachedDataIsValidFor zipcode then  callback null, cache[ zipcode ]
    else updateCacheFor zipcode, (err) -> callback err,  cache[ zipcode ]
        
printAstronomicalData = (data) ->
    try
        {moon_phase} = data
        {percentIlluminated, sunrise, sunset} = moon_phase

        lines = [
            ['moon:    ', "#{percentIlluminated.toString()}% full"]
            ['sunrise: ', "#{sunrise.hour.toString()}:#{sunrise.minute.toString()}"]
            ['sunset:  ', "#{sunset.hour.toString()}:#{sunset.minute.toString()}"]
        ]

        header = '***'.white.bold + " astronomy for #{zip} ".red.bold + '***'.white.bold
        formattedLines = (' --> '.white.bold + line[0].toString().red + ' ' + line[1].toString().white for line in lines)

        console.log header
        console.log formattedLines.join('\n')

    catch err
        handleError 'printAstronomicalData', err


exports.printAstronomicalData = (_apiKey, _zipcode) ->
    apiKey = _apiKey
    zip    = _zipcode

    getDataFor zip, (err, data) ->
        if err? then handleError 'main', err
        else printAstronomicalData(data)
    
    



