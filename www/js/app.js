// Generated by CoffeeScript 1.9.1
(function() {
  var app;

  app = angular.module('app', ['ionic', 'kinvey', 'app.services', 'angularLoad']);

  app.run(function($ionicPlatform) {
    $ionicPlatform.ready(function() {
      if (window.cordova && window.cordova.plugins.Keyboard) {
        cordova.plugins.Keyboard.hideKeyboardAccessoryBar(true);
      }
      if (window.StatusBar) {
        StatusBar.styleDefault();
      }
    });
  });

  app.config(function($stateProvider, $urlRouterProvider) {
    $stateProvider.state('player', {
      url: '/player',
      abstract: true,
      templateUrl: 'templates/player.html',
      controller: 'AppCtrl'
    }).state('tab', {
      url: '/tab',
      abstract: true,
      templateUrl: 'templates/tabs.html',
      controller: 'AppCtrl'
    }).state('wrapper', {
      url: '/wrapper',
      abstract: true,
      templateUrl: 'templates/wrapper.html',
      controller: 'AppCtrl'
    }).state('tab.review', {
      url: '/review',
      views: {
        'tab-review': {
          templateUrl: 'templates/tab-review.html',
          controller: 'ReviewCtrl'
        }
      }
    }).state('tab.read', {
      url: '/read',
      views: {
        'tab-read': {
          templateUrl: 'templates/tab-read.html',
          controller: 'ReadCtrl'
        }
      }
    }).state('tab.edit', {
      url: '/edit',
      views: {
        'tab-edit': {
          templateUrl: 'templates/tab-edit.html',
          controller: 'EditCtrl'
        }
      }
    }).state('player.read', {
      url: '/read/:bookId',
      views: {
        'pages': {
          templateUrl: 'templates/player-read.html',
          controller: 'PlayerCtrl'
        }
      }
    }).state('wrapper.read', {
      url: '/settings',
      views: {
        'wrapper': {
          templateUrl: 'templates/settings.html',
          controller: 'SettingsCtrl'
        }
      }
    });
    $urlRouterProvider.otherwise('/tab/read');
  });

}).call(this);
