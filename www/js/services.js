angular.module('starter.services', [])

.factory('Books', function() {
  // Might use a resource here that returns a JSON array

  // Some fake testing data
  var books = [{
    id: 0,
    name: 'Corduroy',
    author: 'Don Freeman',
    cover: 'http://ecx.images-amazon.com/images/I/51TjUjYpcaL._SL300_.jpg'
  }, {
    id: 1,
    name: 'Make Way for Ducklings',
    author: 'Robert McCloskey',
    cover: 'http://ecx.images-amazon.com/images/I/51vI0NnMsAL._SL300_.jpg'
  }, {
    id: 2,
    name: 'Blueberries for Sal',
    author: 'Robert McCloskey',
    cover: 'http://ecx.images-amazon.com/images/I/61h5CTNZaNL._SL300_.jpg'
  }, {
    id: 3,
    name: 'Goodnight Moon',
    author: 'Margaret Wise Brown',
    cover: 'http://ecx.images-amazon.com/images/I/61ByW7zgleL._SL300_.jpg'
  }, {
    id: 4,
    name: 'Harry The Dirty Dog',
    author: 'Gene Zion',
    cover: 'http://ecx.images-amazon.com/images/I/51J+Gd1L9AL._SL300_.jpg'
  }];

  return {
    all: function() {
      return books;
    },
    remove: function(book) {
      chats.splice(books.indexOf(book), 1);
    },
    get: function(bookId) {
      for (var i = 0; i < books.length; i++) {
        if (books[i].id === parseInt(bookId)) {
          return books[i];
        }
      }
      return null;
    }
  };
});
