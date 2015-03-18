// Generated by CoffeeScript 1.9.1
(function() {
  var app, chunk;

  chunk = function(arr, size) {
    var i, newArr;
    newArr = [];
    i = 0;
    while (i < arr.length) {
      newArr.push(arr.slice(i, i + size));
      i += size;
    }
    return newArr;
  };

  app = angular.module('app');

  app.controller('AppCtrl', [
    "$scope", "$ionicModal", "$rootScope", "$timeout", "$kinvey", function($scope, $ionicModal, $rootScope, $timeout, $kinvey) {
      var promise;
      $scope.loginData = {};
      $scope.signupData = {};
      $ionicModal.fromTemplateUrl("templates/login.html", {
        scope: $scope
      }).then(function(loginmodal) {
        $scope.loginmodal = loginmodal;
      });
      $ionicModal.fromTemplateUrl("templates/signup.html", {
        scope: $scope
      }).then(function(signupmodal) {
        $scope.signupmodal = signupmodal;
      });
      promise = $kinvey.init({
        appKey: "kid_bkOlUtsa2",
        appSecret: "3e534d0a09d6494d916a07c9e6afe54a",
        sync: {
          enable: true
        }
      });
      promise.then(function(kinveyUser) {
        var getUserBooks;
        getUserBooks = function() {
          var query;
          $rootScope.books = [];
          query = new $kinvey.Query();
          query.contains("sharedWith", [$rootScope.activeUser._id]);
          promise = $kinvey.DataStore.find("Books", query);
          return promise.then(function(books) {
            $rootScope.books = books;
            return $rootScope.libraryLayout = chunk(books, 3);
          });
        };
        $scope.openLogin = function() {
          $scope.loginmodal.show();
        };
        $scope.closeLogin = function() {
          $scope.loginmodal.hide();
        };
        $scope.closeSignup = function() {
          $scope.signupmodal.hide();
        };
        $scope.openSignup = function() {
          var getAllLanguages;
          $scope.loginmodal.hide();
          getAllLanguages = function() {
            promise = $kinvey.DataStore.find('Languages');
            return promise.then(function(listOfLanguages) {
              $scope.listOfLanguages = listOfLanguages;
              $scope.signupmodal.show();
              return listOfLanguages;
            });
          };
          if ($kinvey.getActiveUser()) {
            return getAllLanguages();
          } else {
            promise = $kinvey.User.login({
              username: "user",
              password: "password"
            });
            return promise.then(function(tempUser) {
              return getAllLanguages();
            });
          }
        };
        $scope.logout = function() {
          return $kinvey.User.logout().then(function() {
            $rootScope.activeUser === null;
            $scope.openLogin();
          });
        };
        $scope.doLogin = function() {
          var logIntoKinvey;
          logIntoKinvey = function() {
            promise = $kinvey.User.login({
              username: $scope.loginData.username.toLowerCase(),
              password: $scope.loginData.password
            });
            return promise.then(function(activeUser) {
              $rootScope.activeUser = activeUser;
              getUserBooks().then(function() {
                return $scope.closeLogin();
              });
            });
          };
          if ($kinvey.getActiveUser()) {
            return $kinvey.User.logout().then(function() {
              return logIntoKinvey();
            });
          } else {
            return logIntoKinvey();
          }
        };
        $scope.doSignup = function() {
          var logoutPromise;
          logoutPromise = $kinvey.User.logout();
          return logoutPromise.then(function() {
            var formData, signup_promise;
            formData = {
              username: $scope.signupData.username.toLowerCase(),
              password: $scope.signupData.password,
              email: $scope.signupData.username.toLowerCase(),
              language: $scope.signupData.language._id,
              speed: 1
            };
            signup_promise = $kinvey.User.signup(formData);
            return signup_promise.then(function(activeUser) {
              $rootScope.activeUser = activeUser;
              return getUserBooks().then(function() {
                return $scope.closeSignup();
              });
            });
          });
        };
        if (kinveyUser) {
          if (kinveyUser.username === "user") {
            return $scope.openLogin();
          } else {
            $rootScope.activeUser = kinveyUser;
            return getUserBooks().then(function() {});
          }
        } else {
          return $scope.openLogin();
        }
      });
    }
  ]);

  app.controller('ReadCtrl', ["$rootScope", "$scope", "$kinvey", "$stateParams", "kinveyFactory", function($rootScope, $scope, $kinvey, $stateParams, kinveyFactory) {}]);

  app.controller('ReviewCtrl', function($scope) {});

  app.controller('PlayerCtrl', [
    "$kinvey", "$location", "$scope", "$stateParams", "kinveyFactory", function($kinvey, $location, $scope, $stateParams, kinveyFactory) {
      var u;
      kinveyFactory.then(function() {
        var pageQuery, promise;
        pageQuery = new $kinvey.Query();
        pageQuery.equalTo('bookId', $stateParams.bookId);
        promise = $kinvey.DataStore.find("Pages", pageQuery);
        promise.then(function(pages) {
          return console.log(pages);
        });
      });
      u = new SpeechSynthesisUtterance;
      $scope.speak = function(text) {
        u.text = text;
        u.lang = 'en-US';
        speechSynthesis.speak(u);
      };
    }
  ]);

  app.controller('EditCtrl', function($scope) {
    $scope.settings = {
      enableFriends: true
    };
  });

}).call(this);
