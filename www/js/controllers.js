angular.module('starter.controllers', [])

.controller('ReviewCtrl', function($scope) {})

.controller('ReadCtrl', function($scope, Books) {
  $scope.books = chunk(Books.all(), 3);
  $scope.remove = function(books) {
    Books.remove(book);
  }
})

.controller('PlayerCtrl', function($scope, $stateParams, Books) {
  var u = new SpeechSynthesisUtterance();
  $scope.book = Books.get($stateParams.bookId);
  $scope.speak = function(text) {
    u.text = text;
    u.lang = "en-US";
    speechSynthesis.speak(u);
  }
})

.controller('EditCtrl', function($scope) {
  $scope.settings = {
    enableFriends: true
  };
});

function chunk(arr, size) {
  var newArr = [];
  for (var i=0; i<arr.length; i+=size) {
    newArr.push(arr.slice(i, i+size));
  }
  return newArr;
}