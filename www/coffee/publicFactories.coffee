app = angular.module('app')

app.factory 'Camera', [
  '$q'
  ($q) ->
    { 
      getPicture: (options) ->
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

app.factory 'uploadContent', [
  "$kinvey"
  ($kinvey) ->
    {
      uploadFile: (data) ->
        console.log data.image
        upload_promise = $kinvey.File.upload(data.image,
            mimeType: "image/jpeg"
            size: data.size
            _public: true
        )
        upload_promise.then (file) ->
          console.log file
          return {_type: "KinveyFile", _id: file._id}

      uploadModel: (collection, data) ->
        upload_promise = $kinvey.DataStore.save(collection, data)
        upload_promise.then (file) ->
          return file
    }
]