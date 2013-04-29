YelpLib = require 'yelp'
YelpSessionCache = require './yelp-session-cache'

class WebCraftYelpService

  configure: (@oauthConfig, { @adaptBiz, @resultsPerPage, cacheConfig, @debug }, callback)->
    @cache = undefined

    @resultsPerPage ?= 20
    @debug ?=false
    @adaptBiz ?= (biz) -> biz

    @YelpLibClient = YelpLib.createClient @oauthConfig

    if cacheConfig?.url?
      cacheConfig.debug ?= @debug
      @cache = new YelpSessionCache @
      @cache.configure cacheConfig, (err, ok)=> 
        callback?(null, @)
    else
      callback?(null, @)
    @

  # Fetch a biz by its yelpId an cache it if session is given
  fetch: (yelpId, sessionId, callback)=>
    # doesn't seem to work for yelpId with special chars: julios-café-austin-2 !!
    { sessionId, callback } = sortOutSessionIdCallback sessionId, callback
    if sessionId? and @cache?.enabled
      @cache.biz(yelpId, sessionId, callback)
    else
      @fetchById(yelpId, callback)

  # need to create a socket version of this to return each biz 1 at a time (asynchrounously) as they are retrieved
  fetchList: (yelpIdList, sessionId, callback)=>
    { sessionId, callback } = sortOutSessionIdCallback sessionId, callback
    list = []
    for yelpId in yelpIdList
      @fetch yelpId, sessionId, (err, biz)=>
        list.push (biz || { err })
        callback(null, list) if list.length is yelpIdList.length

  # Yelp API Accessors
  fetchById: (yelpId, callback)=>
    @YelpLibClient.business yelpId, (err, yelpBiz)=>
      return callback(err) if err?
      adaptedBiz = @adaptBiz yelpBiz
      callback(err, adaptedBiz)

  fetchByName: (name, location, callback) =>
    searchQuery = 
      term:     name
      location: location
      offset:   0
      limit:    1
    @_search searchQuery, (err, searchResults)=>
      return callback err if err?
      return callback null, null unless searchResults.businesses?.length?
      callback err, searchResults.businesses[0]

  search: (term, location, page, callback)=>
    { page, callback } = sortOutPageCallback page, callback
    page ?= 1 
    page = 1 if page < 1
    searchQuery =
      term:     term
      location: location
      offset:   (page-1)* @resultsPerPage
      limit:    @resultsPerPage
    @_search(searchQuery, callback)

  _search: (searchQuery, callback)=>
    @YelpLibClient.search searchQuery, (err, searchResults)=>
      callback(err, (@_adaptSearchResults searchResults) )

  _adaptSearchResults: (searchResults)=>
    return searchResults unless searchResults.businesses?.length?
    searchResults.businesses = (@adaptBiz yelpBiz for yelpBiz in searchResults.businesses)
    searchResults

configure = (oauthConfig, redisConfig, options, callback)->
  (new WebCraftYelpService).configure(oauthConfig, redisConfig, options, callback)


# some helper utils
sortOutLastArgCallback = (lastArg, callback)->
  return { lastArg, callback } if callback?
  callback = lastArg
  lastArg = undefined
  return { lastArg, callback }

sortOutSessionIdCallback = (sessionId, callback)->
  {lastArg, callback } = sortOutLastArgCallback sessionId, callback
  { sessionId: lastArg, callback }

sortOutPageCallback = (page, callback)->
  {lastArg, callback } = sortOutLastArgCallback page, callback
  { page: lastArg, callback }  


module.exports = { configure }
