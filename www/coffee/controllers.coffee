chunk = (arr, size) ->
  newArr = []
  i = 0
  while i < arr.length
    newArr.push arr.slice(i, i + size)
    i += size
  newArr

app = angular.module('app')

app.controller('AppCtrl', [
  "$scope"
  "$ionicModal"
  "$rootScope"
  "$timeout"
  "$kinvey"
  ($scope, $ionicModal, $rootScope, $timeout, $kinvey) ->
    
    $scope.loginData = {}
    $scope.signupData = {}

    $ionicModal.fromTemplateUrl("templates/login.html",
      scope: $scope
    ).then (loginmodal) ->
      $scope.loginmodal = loginmodal
      return

    $ionicModal.fromTemplateUrl("templates/signup.html",
      scope: $scope
    ).then (signupmodal) ->
      $scope.signupmodal = signupmodal
      return

    promise = $kinvey.init(
          appKey: "kid_bkOlUtsa2"
          appSecret: "3e534d0a09d6494d916a07c9e6afe54a"
          sync:
              enable: true
      )
    promise.then (kinveyUser) ->

      getUserBooks = ->
        $rootScope.books = []
        query = new $kinvey.Query()
        query.contains("sharedWith", [$rootScope.activeUser._id])
        promise = $kinvey.DataStore.find( "Books", query )
        promise.then (books) ->
          $rootScope.books = books
          $rootScope.libraryLayout = chunk(books, 3)

      $scope.openLogin = ->
        $scope.loginmodal.show()
        return

      $scope.closeLogin = ->
        $scope.loginmodal.hide()
        return

      $scope.closeSignup = ->
        $scope.signupmodal.hide()
        return

      $scope.openSignup = ->
        $scope.loginmodal.hide()

        getAllLanguages = ->
          promise = $kinvey.DataStore.find('Languages')

          promise.then ( listOfLanguages ) ->
            $scope.listOfLanguages = listOfLanguages
            $scope.signupmodal.show()
            return listOfLanguages

        if $kinvey.getActiveUser()
          getAllLanguages()
        else
          promise = $kinvey.User.login(
              username: "user"
              password: "password"
            )
          promise.then (tempUser) ->
            getAllLanguages()

      $scope.logout = ->
        $kinvey.User.logout().then () ->
          $rootScope.activeUser == null
          $scope.openLogin()
          return

      $scope.doLogin = ->

        logIntoKinvey = ->
          promise = $kinvey.User.login({
              username : $scope.loginData.username.toLowerCase()
              password: $scope.loginData.password
            })
          promise.then (activeUser) ->
            $rootScope.activeUser = activeUser
            getUserBooks().then () ->
              $scope.closeLogin()
            return

        if $kinvey.getActiveUser()
          $kinvey.User.logout().then () ->
            logIntoKinvey()
        else
          logIntoKinvey()

      $scope.doSignup = ->

        logoutPromise = $kinvey.User.logout()
        logoutPromise.then () ->
          formData = {
            username: $scope.signupData.username.toLowerCase()
            password: $scope.signupData.password
            email: $scope.signupData.username.toLowerCase()
            language: $scope.signupData.language._id
            speed: 1
          }
          signup_promise = $kinvey.User.signup(formData)
          signup_promise.then (activeUser) ->
            $rootScope.activeUser = activeUser
            getUserBooks().then () ->
              $scope.closeSignup()

      if kinveyUser
        if kinveyUser.username == "user"
          $scope.openLogin()
        else 
          $rootScope.activeUser = kinveyUser
          getUserBooks().then () ->
            return
      else
        $scope.openLogin()

    return
])

app.controller('ReadCtrl', [
  "$rootScope"
  "$scope"
  "$kinvey"
  "$stateParams"
  "kinveyFactory"
  ($rootScope, $scope, $kinvey, $stateParams, kinveyFactory) ->
    return
])

app.controller('ReviewCtrl', ($scope) ->
)

app.controller('PlayerCtrl', [
  "$kinvey"
  "$location"
  "$scope"
  "$stateParams"
  "kinveyFactory"
  ($kinvey, $location, $scope, $stateParams, kinveyFactory) ->
    kinveyFactory.then () ->
      pageQuery = new $kinvey.Query()    
      pageQuery.equalTo('bookId', $stateParams.bookId)
      bookPromise = $kinvey.DataStore.get("Books", $stateParams.bookId)
      bookPromise.then (book) ->
        $scope.book = book
        console.log $scope.book
        promise = $kinvey.DataStore.find( "Pages", pageQuery )
        promise.then (pages) ->
          $scope.pages = pages
          console.log $scope.pages
      return

    u = new SpeechSynthesisUtterance

    $scope.speak = (text) ->
      u.text = text
      u.lang = 'en-US'
      speechSynthesis.speak u
      return

    return
])

app.controller 'EditCtrl', ($scope) ->
  $scope.settings = enableFriends: true
  return