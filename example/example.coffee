WebCraftYelpService = require '../index' # require 'web-craft-yelp'

# set up for your oauth token secret key
yelpOAuth =
  wsid: process.env.YELP_WSID
  consumer_key: process.env.YELP_CONSUMER_KEY
  consumer_secret: process.env.YELP_CONSUMER_SECRET
  token: process.env.YELP_TOKEN
  token_secret: process.env.YELP_TOKEN_SECERT

# setup for caching with redis (session caching conforms to Yelp API developer's agreement)
cacheConfig =
  url: process.env.WEB_CRAFT_YELP_REDIS_URL || 'redis://127.0.0.1:6379'
  dbNumber: process.env.WEB_CRAFT_YELP_REDIS_DB_NUMBER || 1
  prefix: 'wy.'
  bizTTL: 5 # 5*60*60     # 5hrs = 5*60s*60m
  sessionTTL: 5 #1*60*60  # 1hr  = 1*60s*60m

# adapt biz information returned from Yelp API for your needs
adaptBiz = (biz)-> 
  return biz unless biz?
  id: biz.id
  name: biz.name
  display_phone: biz.display_phone
  url: biz.url
  rating: biz.rating
  review_count: biz.review_count
  reviews: biz.reviews

# bring it all together to setup the service
serviceSettings =
  debug: false
  resultsPerPage: 20
  adaptBiz: adaptBiz
  cacheConfig: cacheConfig

# Example Usage for a webCraftYelpService
runExamples = (webCraftYelpService)->
  console.log 'Running Examples:'

  startTime1 = Date.now()
  webCraftYelpService.biz 'lax-los-angeles', 'sessionId-1', (err, results)->
    duration = Date.now() - startTime1
    showResults "biz (took #{duration}ms)", err, results

# configure a webCraftYelpService and runExamples
WebCraftYelpService.configure yelpOAuth, serviceSettings, (err, service)->
  console.log 'First Run'
  runExamples(service)

  # wait a couple seconds for results to come back and get cached, then run example again
  setTimeout ( ->
    console.log 'Second Run'
    runExamples(service)
    ), 2000

  # quit after a while
  setTimeout ( ->
    console.log separatorBar, "done", separatorBar
    process.exit(0) 
    ), 5000

# print out formatting
spacer = '\n\n'
separatorBar = '\n-----------------------------------------\n'
showResults = (forWhat, err, results)->
    console.log 'Error: ', err if err?
    console.log separatorBar, results, separatorBar, "Results for ", forWhat, separatorBar
    console.log spacer

