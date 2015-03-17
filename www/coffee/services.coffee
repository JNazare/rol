angular.module('starter.services', []).factory 'Books', ->
  # Might use a resource here that returns a JSON array
  # Some fake testing data
  books = [
    {
      id: 0
      name: 'Corduroy'
      author: 'Don Freeman'
      cover: 'http://ecx.images-amazon.com/images/I/51TjUjYpcaL._SL300_.jpg'
    }
    {
      id: 1
      name: 'Make Way for Ducklings'
      author: 'Robert McCloskey'
      cover: 'http://ecx.images-amazon.com/images/I/51vI0NnMsAL._SL300_.jpg'
    }
    {
      id: 2
      name: 'Blueberries for Sal'
      author: 'Robert McCloskey'
      cover: 'http://ecx.images-amazon.com/images/I/61h5CTNZaNL._SL300_.jpg'
    }
    {
      id: 3
      name: 'Goodnight Moon'
      author: 'Margaret Wise Brown'
      cover: 'http://ecx.images-amazon.com/images/I/61ByW7zgleL._SL300_.jpg'
    }
    {
      id: 4
      name: 'Harry The Dirty Dog'
      author: 'Gene Zion'
      cover: 'http://ecx.images-amazon.com/images/I/51J+Gd1L9AL._SL300_.jpg'
    }
  ]
  {
    all: ->
      books
    remove: (book) ->
      chats.splice books.indexOf(book), 1
      return
    get: (bookId) ->
      i = 0
      while i < books.length
        if books[i].id == parseInt(bookId)
          return books[i]
        i++
      null

  }