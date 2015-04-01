appServices = angular.module('app.services', [])

appServices.factory 'privateFactory', [ 
  "$kinvey" 
  ($kinvey) ->
    appKey = "kid_bkOlUtsa2"
    appSecret = "3e534d0a09d6494d916a07c9e6afe54a"

    kinveyKey: ->
      return appKey
    kinveySecret: ->
      return appSecret
]
