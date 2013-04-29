WebCraftYelpService = require '../../index'

MAX_CACHE_LOOKUP_DURATION = 8 # milliseconds

oAuth =
  wsid: process.env.YELP_WSID
  consumer_key: process.env.YELP_CONSUMER_KEY
  consumer_secret: process.env.YELP_CONSUMER_SECRET
  token: process.env.YELP_TOKEN
  token_secret: process.env.YELP_TOKEN_SECERT

# setup for caching with redis (session caching conforms to Yelp API developer's agreement)
cacheConfig =
  url: process.env.WEB_CRAFT_YELP_REDIS_URL || 'redis://127.0.0.1:6379'
  dbNumber: 7
  prefix: 'wy.'
  bizTTL: 5 # 5*60*60     # 5hrs = 5*60s*60m
  sessionTTL: 5 #1*60*60  # 1hr  = 1*60s*60m

# adapt biz information returned from Yelp API for your needs
adaptBiz = (biz)-> 
  return biz unless biz?
  id: biz.id
  name: biz.name
  rating: biz.rating
  review_count: biz.review_count
  reviews: biz.reviews

# bring it all together to setup the service
serviceSettings =
  debug: false
  resultsPerPage: 20
  adaptBiz: adaptBiz
  cacheConfig: cacheConfig

describe 'WebCraftYelpService', ->
  biz = undefined
  yelpId = 'lax-los-angeles'
  yelpCraftService = undefined

  before (done)->
    WebCraftYelpService.configure oAuth, serviceSettings, (err, service)->
      yelpCraftService = service
      yelpCraftService.cache.clear (err, keyCount)->
        console.log "deleted #{keyCount} keys from cache" unless 0 is keyCount
        done()

  after (done)->
    yelpCraftService.cache.clear (err, keyCount)->
      done()

  context 'without a session', ->
    it 'fetches and does not cache the result', (done)->
      yelpCraftService.cache.keyCount (err, keyCount)->
        expect(keyCount).to.equal 0 # check that cache is empty

        yelpCraftService.fetch yelpId, null, (err, biz)->
          expect(biz.name).to.equal 'LAX' # fetch the biz

          yelpCraftService.cache.keyCount (err, keyCount)->
            expect(keyCount).to.equal 0  # check that cache is still empty
            done()

  context 'with a session', ->
    sessionId = 'sess-123'

    it 'fetches a biz and caches it', (done)->
      yelpCraftService.cache.keyCount (err, keyCount)->
        expect(keyCount).to.equal 0  # check that cache is empty

        yelpCraftService.fetch yelpId, sessionId, (err, biz)->
          expect(biz.name).to.equal 'LAX' # expect the biz to have been fetched

          setTimeout (-> # allow a moment for cache to store the result
            yelpCraftService.cache.keyCount (err, keyCount)->
              expect(keyCount).to.be.greaterThan 0  # check that cache is no longer empty
              done()
            ), 88

    it 'fetches the same biz from cache', (done)->
      startTime = Date.now()
      yelpCraftService.fetch yelpId, sessionId, (err, biz)-> # fetch the same biz, this time from cache(?)
        duration = Date.now() - startTime
        expect(biz.name).to.equal 'LAX' # expect the biz to have been fetched
        expect(duration).to.be.lessThan MAX_CACHE_LOOKUP_DURATION # make sure it doesn't take long to get it from cache
        done()
