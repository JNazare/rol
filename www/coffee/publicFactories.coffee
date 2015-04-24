app = angular.module('app')

chunk = (arr, size) ->
  newArr = []
  i = 0
  while i < arr.length
    newArr.push arr.slice(i, i + size)
    i += size
  newArr

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
        upload_promise = $kinvey.File.upload(data.image,
            mimeType: "image/jpeg"
            size: data.size
            _public: true
        )
        upload_promise.then (file) ->
          return {_type: "KinveyFile", _id: file._id}

      uploadModel: (collection, data) ->
        upload_promise = $kinvey.DataStore.save(collection, data)
        upload_promise.then (file) ->
          return file

      updateModel: (collection, data) ->
        upload_promise = $kinvey.DataStore.update(collection, data)
        upload_promise.then (file) ->
          return file

      deleteModel: (collection, id) ->
        delete_promise = $kinvey.DataStore.destroy(collection, id)
        delete_promise.then () ->
          return 'done'
    }
]

app.factory 'Library', [
  "$kinvey"
  ($kinvey) ->
    {
      getShelf : (books) ->
        add_book = {
          coverImageUrl: "img/add_book_icon.jpg"
          add_url: "add"
        }
        books.unshift(add_book)
        return chunk(books, 3)
    }
]