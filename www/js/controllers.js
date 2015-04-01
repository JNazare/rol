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

  app.filter('splitParagraphs', function() {
    return function(text) {
      return text.split('\n');
    };
  });

  app.filter('splitWords', function() {
    return function(text) {
      return text.split(' ');
    };
  });

  app.controller('AppCtrl', [
    "$scope", "$ionicModal", "$rootScope", "$timeout", "$kinvey", "privateFactory", function($scope, $ionicModal, $rootScope, $timeout, $kinvey, privateFactory) {
      var promise;
      console.log('in app ctrl');
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
        appKey: privateFactory.kinveyKey(),
        appSecret: privateFactory.kinveySecret(),
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
            return $rootScope.books = books;
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
                var loginEvent;
                loginEvent = 'loginEvent';
                $scope.$broadcast(loginEvent);
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
                var loginEvent;
                loginEvent = 'loginEvent';
                $scope.$broadcast(loginEvent);
                return $scope.closeSignup();
              });
            });
          });
        };
        if (kinveyUser) {
          if (kinveyUser.username === "user") {
            $scope.openLogin();
          } else {
            $rootScope.activeUser = kinveyUser;
            return getUserBooks().then(function() {
              var loginEvent;
              loginEvent = 'loginEvent';
              $scope.$broadcast(loginEvent);
            });
          }
        } else {
          $scope.openLogin();
        }
      });
    }
  ]);

  app.controller('ReadCtrl', [
    "$rootScope", "$scope", "$kinvey", "$stateParams", "privateFactory", function($rootScope, $scope, $kinvey, $stateParams, privateFactory) {
      console.log('in read ctrl');
      $scope.$on('loginEvent', function() {
        var add_book, books_to_chunk;
        add_book = {
          coverImageUrl: "img/add_book_icon.jpg",
          add_url: "tab/edit"
        };
        books_to_chunk = $scope.books;
        books_to_chunk.unshift(add_book);
        $rootScope.libraryLayout = chunk(books_to_chunk, 3);
      });
    }
  ]);

  app.controller('ReviewCtrl', function($scope) {
    return console.log('in review ctrl');
  });

  app.controller('PlayerCtrl', [
    "$kinvey", "$location", "$scope", "$stateParams", "$rootScope", "$ionicSlideBoxDelegate", "$http", function($kinvey, $location, $scope, $stateParams, $rootScope, $ionicSlideBoxDelegate, $http) {
      var bookPromise, defineUtterance1, defineUtterance2, pageQuery, playUtterance;
      pageQuery = new $kinvey.Query();
      pageQuery.equalTo('bookId', $stateParams.bookId);
      bookPromise = $kinvey.DataStore.get("Books", $stateParams.bookId);
      bookPromise.then(function(book) {
        var promise;
        $scope.book = book;
        promise = $kinvey.DataStore.find("Pages", pageQuery);
        return promise.then(function(pages) {
          var book_display_data;
          book_display_data = {
            image: {
              _downloadURL: book.coverImageUrl
            },
            text: book.title + " by " + book.author
          };
          pages.unshift(book_display_data);
          $scope.pages = pages;
          $ionicSlideBoxDelegate.update();
          promise = $kinvey.DataStore.get('Languages', $rootScope.activeUser.language);
          return promise.then(function(translationLanguage) {
            return $scope.translationLanguage = translationLanguage;
          });
        });
      });
      $scope.currentSlide = 0;
      $scope.playing = false;
      playUtterance = new SpeechSynthesisUtterance;
      defineUtterance1 = new SpeechSynthesisUtterance;
      defineUtterance2 = new SpeechSynthesisUtterance;
      playUtterance.onend = function() {
        $scope.$apply(function() {
          $scope.playing = false;
        });
      };
      playUtterance.onpause = function() {};
      defineUtterance1.onend = function() {
        speechSynthesis.speak(defineUtterance2);
      };
      $scope.slideHasChanged = function(newSlide) {
        $scope.currentSlide = newSlide;
      };
      $scope.slideTo = function(slideNum) {
        speechSynthesis.cancel();
        $scope.playing = false;
        return $ionicSlideBoxDelegate.slide(slideNum);
      };
      $scope.slidePrevious = function() {
        speechSynthesis.cancel();
        $scope.playing = false;
        $ionicSlideBoxDelegate.previous();
      };
      $scope.slideNext = function() {
        speechSynthesis.cancel();
        $scope.playing = false;
        $ionicSlideBoxDelegate.next();
      };
      $scope.speak = function(text, lang) {
        $scope.playing = true;
        if (speechSynthesis.speaking === true) {
          speechSynthesis.resume();
        } else {
          playUtterance.text = text;
          playUtterance.lang = lang;
          playUtterance.localService = true;
          speechSynthesis.speak(playUtterance);
        }
      };
      $scope.pause = function() {
        speechSynthesis.cancel();
        $scope.playing = false;
      };
      $scope.endBook = function() {
        speechSynthesis.cancel();
        $scope.playing = false;
      };
      $scope.define = function(word) {
        var link, selected_word;
        selected_word = word.trim().replace(/["\.,-\/#!$%\^&\*;:{}=\-_`~()]/g, "");
        link = "https://translation-app.herokuapp.com/api/en/" + $scope.translationLanguage._id + "/" + selected_word;
        $http.get(link).success(function(translated_word, status, headers, config) {
          $scope.selected_word = selected_word;
          $scope.translated_word = translated_word;
          defineUtterance1.text = $scope.selected_word;
          defineUtterance1.lang = "en";
          defineUtterance1.localService = true;
          defineUtterance2.text = $scope.translated_word;
          defineUtterance2.lang = $scope.translationLanguage._id;
          defineUtterance2.localService = true;
          speechSynthesis.speak(defineUtterance1);
        }).error(function(data, status, headers, config) {
          return 'error';
        });
      };
    }
  ]);

  app.controller('SettingsCtrl', [
    "$ionicHistory", "$scope", "$kinvey", "$rootScope", "$ionicPopup", function($ionicHistory, $scope, $kinvey, $rootScope, $ionicPopup) {
      var promise;
      promise = $kinvey.DataStore.find('Languages');
      promise.then(function(listOfLanguages) {
        $scope.listOfLanguages = listOfLanguages;
      });
      $scope.goBack = function() {
        $ionicHistory.goBack();
      };
      $scope.updateUser = function() {
        promise = $kinvey.User.update($rootScope.activeUser);
        return promise.then(function() {
          var alertPopup;
          alertPopup = $ionicPopup.alert({
            title: 'SAVED'
          });
        });
      };
    }
  ]);

  app.controller('PracticeCtrl', [
    "$ionicHistory", "$scope", "$kinvey", "$rootScope", "$ionicPopup", function($ionicHistory, $scope, $kinvey, $rootScope, $ionicPopup) {
      return $scope.goBack = function() {
        $ionicHistory.goBack();
      };
    }
  ]);

  app.controller('EditCtrl', function($scope) {
    $scope.settings = {
      enableFriends: true
    };
  });

}).call(this);
