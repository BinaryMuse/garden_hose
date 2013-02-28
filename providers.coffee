{EventEmitter} = require 'events'
redis = require 'redis'
geoip = require 'geoip-lite'
Faker = require 'faker'

# A Provider is a class that emits 'activity' events. The only
# parameter to that event should be an item that represents that
# activity item:
#
#   item =
#     object:
#       title: 'The title of the item'
#       id: 'The ActiveRecord ID of the item'
#       type: 'The ActiveRecord class of the item'
#     coordinates: [
#       { lat: 'latitude', lng: 'longitude' }
#     ]
#
# where 'latitude' and 'longitude' represent the latitude and
# longitude coordinates of the user we want to make a ping for.
#
# The configuration options specified in config.toml will be
# provided to the constructor of the given provider.

class FakeProvider extends EventEmitter
  constructor: (config) ->
    super()
    @types = ['Board', 'Learning']
    @minFrequency = config.minFrequency ? 1000
    @maxFrequency = config.maxFrequency ? 10000
    @minItems = config.minItems ? 1
    @maxItems = config.maxItems ? 10
    @generate()

  generate: =>
    itemCountDiff = @maxItems - @minItems
    itemCount = Math.random() * itemCountDiff + @minItems

    item =
      object:
        title: Faker.Company.catchPhrase()
        id: Math.ceil(Math.random() * 10000)
        type: @types[Math.floor(Math.random() * @types.length)]
      coordinates: (@generateCoord() for i in [1..itemCount])

    @emit 'activity', item

    frequencyDiff = @maxFrequency - @minFrequency
    time = Math.random() * frequencyDiff + @minFrequency
    setTimeout @generate, time

  generateCoord: =>
    lat = Math.random() * 180 - 90
    lng = Math.random() * 360 - 180
    { lat: lat, lng: lng }

class RedisProvider extends EventEmitter
  constructor: (config) ->
    super()
    @server = config.server
    @port = config.port ? 6379
    @dbNum = config.dbNum ? 0
    @channel = config.channel

    @redis = redis.createClient @port, @server
    @redis.on 'message', @handleMessage
    @redis.subscribe @channel

  handleMessage: (channel, msg) =>
    json = JSON.parse(msg)
    geos = (@getGeo(ip) for ip in json.user_data)
    geos = (geo for geo in geos when geo isnt null)
    json.coordinates = geos
    @emit 'activity', json

  getGeo: (ip) =>
    ip = geoip.lookup(ip)
    if ip?.ll?
      { lat: ip.ll[0], lng: ip.ll[1] }
    else
      null

# Key names here represent the 'type' configuration option
# in config.toml
module.exports =
  fake: FakeProvider
  redis: RedisProvider
