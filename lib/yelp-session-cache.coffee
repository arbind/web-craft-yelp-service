###
YelpSessionCache
  Ensure Cache compliance for Yelp API developer's agreement
  Handles 4 situations:
  1. empty:  biz is not in cache (1st ever search for biz)
    request to Yelp is required
  2. cached: biz is in cache, and in session (user already searched for biz durring the session)
    request to Yelp not required
  3. expired biz is in cache, but not in session (user searched for biz before, but the session expired)
    request to Yelp is required (return cached biz for performance, then update cache to keep it real-time )
  4. shared: biz is in cache, but not in session (1st search for biz by this user, but biz was alreay put in cache from another user)
    request to Yelp is required (return cached biz for performance, then update cache to keep it real-time )
###

ERROR_NOT_CONNECTED = new Error 'Error: Yelp Session Cache Not Connected to redis!'

class YelpSessionCache
  constructor: (@webcraftYelpService)->

  configure: (redisConfig, callback)=>
    dbNumber = redisConfig.dbNumber ?= 0
    @prefix = redisConfig?.prefix ? 'wy.'
    @bizTTL = redisConfig?.bizTTL ? 5*60*60        # 5hrs : worst case expiration for a yelp biz, so it doesn't get stale
    @sessionTTL = redisConfig?.sessionTTL ? 60*60  # 1hr = 60s * 60m

    redisTimeoutTimer = undefined
    reportConnectionFailure = ->
      clearTimeout redisTimeoutTimer
      callback?(ERROR_NOT_CONNECTED)
      console.log ERROR_NOT_CONNECTED unless callback?

    redisTimeoutTimer = setTimeout reportConnectionFailure, 5000

    r = require('redis-url').connect(redisConfig.url)
    r.on 'connect', =>
      clearTimeout redisTimeoutTimer
      @redis = r
      @redis.send_anyways = true
      @redis.select dbNumber, (err, val) => 
        @redis.send_anyways = false
        @redis.selectedDB = dbNumber
        console.log "Yelp Session Cache: connected to redis using db##{dbNumber}"
        callback?(null, true)
        if @debug
          @redis.keys '*', (err, keys)=>
            console.log "Yelp Session Cache: #{keys.length} redis keys"

    r.on 'error', (args...)=>
      console.log args...
      reportConnectionFailure()
    @

  biz: (yelpId, sessionId, callback)=>
    return callback(ERROR_NOT_CONNECTED) unless @redis
    @redis.get yelpId, (err, bizJSON)=>
      return callback(err) if err?
      if bizJSON? # found the biz in cache
        yelpBiz = (JSON.parse bizJSON) if bizJSON?
        callback(err, yelpBiz ) # make the biz available immediately
        # issue request to yelp if yelp id is not in the session
        @redis.expire yelpId, @bizTTL # refresh the biz lifetime
        @redis.hexists sessionId, yelpId, (err, alreadyExists)=>
          if 0 isnt alreadyExists # biz is already in session
            @redis.expire sessionId, @sessionTTL # refresh session lifetime
          else # biz is not yet in session
            @webcraftYelpService.bizById yelpId, (err, yelpBiz)=> # issue request to yelp
              return if err?
              @store yelpId, yelpBiz, sessionId
      else # biz is not in cache
        @webcraftYelpService.bizById yelpId, (err, yelpBiz)=> # issue request to yelp
          callback(err, yelpBiz) # make the biz available as soon as possible
          return if err?
          @store yelpId, yelpBiz, sessionId

  store: (yelpId, yelpBiz, sessionId, callback)=>
    throw ERROR_NOT_CONNECTED unless @redis
    bizJSON = (JSON.stringify yelpBiz)
    @redis.set yelpId, bizJSON, (err, ok)=>
      return callback?(err) if err?
      @redis.expire yelpId, @bizTTL
      if sessionId?
        @redis.hmset sessionId, yelpId, ".", (err, ok)=> # add the yelpId to this session
          @redis.expire sessionId, @sessionTTL
          callback?(null, ok)
      else 
        callback?(null, ok)

  clear: (calllback)=>
    throw ERROR_NOT_CONNECTED unless @redis
    @redis.keys '*', (err, keys)=>
      redis.del key for key in keys
      callback?(null, keys.length)

  keyCount: (callback)=>
    throw ERROR_NOT_CONNECTED unless @redis
    @redis.keys '*', (err, keys)-> callback err, keys?.length

module.exports = YelpSessionCache
