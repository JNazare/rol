angular.module('starter.services', [])

.factory('Chats', function() {
  // Might use a resource here that returns a JSON array

  // Some fake testing data
  var chats = [{
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
      return chats;
    },
    remove: function(chat) {
      chats.splice(chats.indexOf(chat), 1);
    },
    get: function(chatId) {
      for (var i = 0; i < chats.length; i++) {
        if (chats[i].id === parseInt(chatId)) {
          return chats[i];
        }
      }
      return null;
    }
  };
});
