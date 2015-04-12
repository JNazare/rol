appServices = angular.module('app.services', [])

appServices.factory 'kinveyKey', ->
  return "kid_bkOlUtsa2"

appServices.factory 'kinveySecret', ->
  return "3e534d0a09d6494d916a07c9e6afe54a"

appServices.factory 'Camera', [
  '$q'
  ($q) ->
    { getPicture: (options) ->
      q = $q.defer()
      navigator.camera.getPicture ((result) ->
        # Do any magic you need
        q.resolve result
        return
      ), ((err) ->
        q.reject err
        return
      ), options
      q.promise
    }
]
