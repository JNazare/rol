# Ionic App
# angular.module is a global place for creating, registering and retrieving Angular modules
# 'app' is the name of this angular module example (also set in a <body> attribute in index.html)
# the 2nd parameter is an array of 'requires'
# 'app.services' is found in services.js
# 'app.controllers' is found in controllers.js

app = angular.module('app', [
  'ionic'
  'kinvey'
  'angularLoad'
  'angulartics'
  'angulartics.mixpanel'
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

app.config ($stateProvider, $urlRouterProvider, $analyticsProvider) ->
  # Ionic uses AngularUI Router which uses the concept of states
  # Learn more here: https://github.com/angular-ui/ui-router
  # Set up the various states which the app can be in.
  # Each state's controller can be found in controllers.js

  $stateProvider.state('app',
    url: ''
    abstract: true
    controller: 'AppCtrl'
    templateUrl: 'templates/wrapper.html'
  ).state('app.home',
    url: ''
    abstract: true
    views: 'wrapper':
      templateUrl: 'templates/tabs.html'
  ).state('app.home.read',
    url: '/library'
    views: 'tab-read':
      templateUrl: 'templates/tab-read.html'
      controller: 'ReadCtrl'
  ).state('app.home.review',
    url: '/review'
    views: 'tab-review':
      templateUrl: 'templates/tab-review.html'
      controller: 'ReviewCtrl'
  ).state('app.read',
    url: '/read/:bookId'
    views: 'wrapper':
      templateUrl: 'templates/player-read.html'
      controller: 'PlayerCtrl'
  ).state('app.settings',
    url: '/settings'
    views: 'wrapper':
      templateUrl: 'templates/settings.html'
      controller: 'SettingsCtrl'
  ).state('app.add',
  url: '/add'
  views: 'wrapper':
    templateUrl: 'templates/add.html'
    controller: 'AddCtrl'
  ).state('app.editbook',
  url: '/editbook/:bookId'
  views: 'wrapper':
    templateUrl: 'templates/editbook.html'
    controller: 'EditBookCtrl'
  ).state('app.editpage',
  url: '/editpage/:bookId/:pageNum'
  views: 'wrapper':
    templateUrl: 'templates/editpage.html'
    controller: 'EditPageCtrl'
  )

  # if none of the above states are matched, use this as the fallback
  $urlRouterProvider.otherwise '/library'
  return


app.config [
  '$compileProvider'
  ($compileProvider) ->
    $compileProvider.imgSrcSanitizationWhitelist(/^\s*(https?|ftp|file|blob):|data:image\//);
    return
]

app.config ($provide) ->
  $provide.decorator '$state', ($delegate, $stateParams) ->

    $delegate.forceReload = ->
      $delegate.go $delegate.current, $stateParams,
        reload: true
        inherit: false
        notify: true

    $delegate
  return

app.config [
  '$httpProvider'
  ($httpProvider) ->
    $httpProvider.defaults.useXDomain = true 
    delete $httpProvider.defaults.headers.common["X-Requested-With"]
    $httpProvider.defaults.headers.common["Accept"] = "application/json"
    $httpProvider.defaults.headers.common["Content-Type"] = "application/json"
    return
]
