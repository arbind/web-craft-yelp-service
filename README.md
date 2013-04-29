# Web Craft Yelp Service
Implements [YelpAPI 2.0 for Developers](http://www.yelp.com/developers/documentation/faq)

## Overview
#### The Web Craft Yelp Service fetches biz info using the yelp API.
Includes option for session cacheing (as specified by Yelp's developer agreement).

## &#10003; Status
Primary. Functional. Complete. Stable. Production Ready.

1. &#10003; fetch biz (by yelpId)
   * &#10003; retrieve from session cache if present
   * &#10003; fetch biz from Yelp and cache it, otherwise
   * &#10003; adapt the result to return only the desired attributes
2. &#10003; session cache for biz (by yelpId) (redis)
   * &#10003; new session always issues request to Yelp API   
   * &#10003; expire session after 60 min
   * &#10003; conform to yelp api developer's agreement in general
3. &#10003; fetchList: find list of biz (by array of yelpIds)
   * &#10003; Look up each one in cache
   * &#10003; Fetch each one from Yelp and cache it, otherwise
   * &Xi; parallelize each fetch (optimize to use redis mget and then async)
4. &#10003; fetchById: find biz (by yelpId)
   * &#10003; returns 1 biz (if found) and does not do any cacheing
5. &#10003; fetchByName: find biz (by name and location)
   * &#10003; returns 1 biz (the first one matched)
6. &#10003; search for businesses (by term and location)
   * &#10003; returns 20 businesses per page
7. &#10003; specs
   * &Xi; specs for API
     * &#10003; fetch (primary)
     * &Xi; fetchList (secondary)
     * &Xi; fetchById (secondary)
     * &Xi; fetchByName (secondary)
     * &Xi; search (secondary)
   * &#10003; specs for cacheing
   
**Key**

&#10003; Complete

&hearts; In Progres

&Xi; ToDo

## Usage

````
YelpService = require 'web-craft-yelp-service'

sessionID = '123'            # or request.sessionID
yelpID = 'lax-los-angeles'   # or any real yelp ID

# see configuration section for oAuth and settings
oAuth = { … } 
settings = { … }
yelp = YelpService.configure oAuth, settings

# some time passes (redis connects, your server starts up, etc..)

yelp.fetch yelpID, sessionID, (err, yelpCraft)->  
  console.log yelpCraft
````
Of course, this is after you go through all the frigin configuration (see below).

## API
```
fetch: (yelpId, sessionId, callback)=>
  # Returns a Yelp biz (from the session cache if possible)
  #
  # yelpId: 
  #  id of the biz to fetch
  #
  # sessionId: 
  #  session token used to identify a  cache
  #
  #  callback:
  #    result is returned by calling callback(err, biz)
  
bizList: (yelpIdList, sessionId, callback)=>
  # Returns a biz array (from the session cache where possible)
  #
  # yelpIdList
  #   array of yelp ids to fetch
  #
  # sessionId: 
  #  session token used to identify a  cache
  #
  #  callback:
  #    results are returned by calling callback(err, bizArray)

bizById: (yelpId, callback)=>
  # Returns a Yelp biz from the Yelp API (doesn't check the cache at all)
  #
  # yelpID: 
  #  id of the biz to fetch
  #
  #  callback:
  #    result is returned by calling callback(err, biz)

bizByName: (name, location, callback) =>
  # Returns 1 Yelp biz from the Yelp API (doesn't check the cache at all)
  #
  # name: 
  #  name of the biz to fetch
  #
  # location: 
  #  as specific an address as possible
  #
  #  callback:
  #    result is returned by calling callback(err, biz)
  # 
  #  * A name match may result in multiple results
  #    this call returns the first match found, if any
  #
  #  * information that Yelp return from a search may not contain 
  #    the same information that Yelp returns from a lookup by yelp ID
  #    For example, the biz reviews may not be included

search: (term, location, page, callback)=>
  # Returns a search results from Yelp API (doesn't check the cache at all)
  #
  # term: 
  #  the search term to find matching business for
  #
  # location: 
  #  as specific an address as possible
  #
  # page: 
  #  page number of the result set to return
  #
  #  callback:
  #    result is returned by calling callback(err, searchResults)
  #
  #  * information that Yelp return from a search may not contain 
  #    the same information that Yelp returns from a lookup by yelp ID
  #    For example, the biz reviews may not be included

```

## Run Specs
The specs make real calls to Yelp, to ensure that the service really works.
If Yelp ever changes their API, the specs should break accordingly.

To run the specs, configure an .env file (see Configure section below) and execute:

```
foreman run cake spec
```

## Run Example
Configure an .env file (see below) and run:

```
foreman run coffee example/example.coffee
```
Open example/example.coffee and have a look.


## Configure
1. Define environment variables
2. Define oAuth token secret key, etc
3. Define yelp session cache (via redis) (optional)
4. Define biz adapter (to see only the atts you want)(optional)
5. configure the service
6. run with foreman (optional) (or pick up the .env variables however you want)

### 1. Define environment variables (one way to do it)
```
cp .env.template .env
touch Procfile
```

Modify the .env file to include your [yelp developer's oauth tokens](http://www.yelp.com/developers/manage_api_keys)

```
YELP_WSID=your_wsid

YELP_CONSUMER_KEY=your_consumer_key
YELP_CONSUMER_SECRET=your_consumer_secret
YELP_TOKEN=your_token
YELP_TOKEN_SECERT=your_token_secret

WEB_CRAFT_YELP_REDIS_DB_NUMBER=1
WEB_CRAFT_YELP_REDIS_URL=redis://127.0.0.1:6379
```

### 2. Define oAuth (required)
```
oAuth =
  wsid: process.env.YELP_WSID
  consumer_key: process.env.YELP_CONSUMER_KEY
  consumer_secret: process.env.YELP_CONSUMER_SECRET
  token: process.env.YELP_TOKEN
  token_secret: process.env.YELP_TOKEN_SECERT
```

### 3. Define yelp session cache (optional)
```
cacheConfig =
  url: process.env.WEB_CRAFT_YELP_REDIS_URL || 'redis://127.0.0.1:6379'
  dbNumber: process.env.WEB_CRAFT_YELP_REDIS_DB_NUMBER || 0
  prefix: 'wy.'
  bizTTL: 5*60*60      # 5hrs = 5*60s*60m
  sessionTTL: 1*60*60  # 1hr  = 1*60s*60m
```
### 4. Define biz adapter (Optional)
Adapt the biz information returned from Yelp API for your needs. 

```
adaptBiz = (biz)-> 
  return biz unless biz?
  id: biz.id
  name: biz.name
  display_phone: biz.display_phone
  url: biz.url
  rating: biz.rating
  review_count: biz.review_count
  reviews: biz.reviews

```
Print out biz to see what information Yelp currently provides.

### 5. Configure the service

```
settings =
  debug: false
  resultsPerPage: 20
  adaptBiz: adaptBiz
  cacheConfig: cacheConfig

sessionID = '123'            # or request.sessionID
yelpID = 'lax-los-angeles'   # or any real yelp ID

YelpService = require 'web-craft-yelp-service'
YelpService.configure oAuth, settings, (err, yelp)->
  yelp.fetch yelpID, sessionID, (err, yelpCraft)->  
    console.log yelpCraft

```

### 6. Run with foreman

````
foreman run coffee example/example.coffee
````

### &Xi; TO DO
+ &Xi; explore an interface that accepts a socket to return results to instead of a callback
