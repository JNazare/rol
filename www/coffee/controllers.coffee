chunk = (arr, size) ->
  newArr = []
  i = 0
  while i < arr.length
    newArr.push arr.slice(i, i + size)
    i += size
  newArr

angular.module('starter.controllers', []).controller('ReviewCtrl', ($scope) ->
).controller('ReadCtrl', ($scope, Books) ->
  $scope.books = chunk(Books.all(), 3)

  $scope.remove = (books) ->
    Books.remove book
    return

  return
).controller('PlayerCtrl', ($scope, $stateParams, Books) ->
  u = new SpeechSynthesisUtterance
  $scope.book = Books.get($stateParams.bookId)

  $scope.speak = (text) ->
    u.text = text
    u.lang = 'en-US'
    speechSynthesis.speak u
    return

  return
).controller 'EditCtrl', ($scope) ->
  $scope.settings = enableFriends: true
  return