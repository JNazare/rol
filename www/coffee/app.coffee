# Ionic App
# angular.module is a global place for creating, registering and retrieving Angular modules
# 'app' is the name of this angular module example (also set in a <body> attribute in index.html)
# the 2nd parameter is an array of 'requires'
# 'app.services' is found in services.js
# 'app.controllers' is found in controllers.js

app = angular.module('app', [
  'ionic'
  'kinvey'
  'app.services'
  'angularLoad'
])

app.run(($ionicPlatform) ->
  $ionicPlatform.ready ->
    # Hide the accessory bar by default (remove this to show the accessory bar above the keyboard
    # for form inputs)
    if window.cordova and window.cordova.plugins.Keyboard
      cordova.plugins.Keyboard.hideKeyboardAccessoryBar true
    if window.StatusBar
      # org.apache.cordova.statusbar required
      StatusBar.styleDefault()
    return
  return
)

app.config ($stateProvider, $urlRouterProvider) ->
  # Ionic uses AngularUI Router which uses the concept of states
  # Learn more here: https://github.com/angular-ui/ui-router
  # Set up the various states which the app can be in.
  # Each state's controller can be found in controllers.js
  $stateProvider.state('player',
      url: '/player'
      abstract: true
      templateUrl: 'templates/player.html'
      controller: 'AppCtrl'
    ).state('tab',
      url: '/tab'
      abstract: true
      templateUrl: 'templates/tabs.html'
      controller: 'AppCtrl'
    ).state('wrapper',
      url: '/wrapper'
      abstract: true
      templateUrl: 'templates/wrapper.html'
      controller: 'AppCtrl'
    ).state('tab.review',
      url: '/review'
      views: 'tab-review':
        templateUrl: 'templates/tab-review.html'
        controller: 'ReviewCtrl'
    ).state('tab.read',
      url: '/read'
      views: 'tab-read':
        templateUrl: 'templates/tab-read.html'
        controller: 'ReadCtrl'
    ).state('tab.edit',
      url: '/edit'
      views: 'tab-edit':
        templateUrl: 'templates/tab-edit.html'
        controller: 'EditCtrl'
    ).state('player.read',
      url: '/read/:bookId'
      views: 'pages':
        templateUrl: 'templates/player-read.html'
        controller: 'PlayerCtrl'
    ).state('wrapper.settings',
    url: '/settings'
    views: 'wrapper':
      templateUrl: 'templates/settings.html'
      controller: 'SettingsCtrl'
    ).state('wrapper.practice',
    url: '/practice'
    views: 'wrapper':
      templateUrl: 'templates/practice.html'
      controller: 'PracticeCtrl'
    )
  
  # if none of the above states are matched, use this as the fallback
  $urlRouterProvider.otherwise '/tab/read'
  return