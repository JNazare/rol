chunk = (arr, size) ->
  newArr = []
  i = 0
  while i < arr.length
    newArr.push arr.slice(i, i + size)
    i += size
  newArr

dataURItoBlob = (dataURI) ->
  binary = atob(dataURI.split(',')[1])
  array = []
  i = 0
  while i < binary.length
    array.push binary.charCodeAt(i)
    i++
  new Blob([ new Uint8Array(array) ], type: 'image/jpeg')

app = angular.module('app')

app.filter 'splitParagraphs', ->
  (text) ->
    text.split '\n'

app.filter 'splitWords', ->
  (text) ->
    text.split ' '

app.controller('AppCtrl', [
  "$scope"
  "$ionicModal"
  "$rootScope"
  "$timeout"
  "$kinvey"
  "kinveyKey"
  "kinveySecret"
  ($scope, $ionicModal, $rootScope, $timeout, $kinvey, kinveyKey, kinveySecret) ->
    
    console.log 'in app ctrl'

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
          appKey: kinveyKey
          appSecret: kinveySecret
          sync:
              enable: true
      )
    promise.then (kinveyUser) ->

      $rootScope.getUserBooks = ->
        $rootScope.books = []
        query = new $kinvey.Query()
        query.contains("sharedWith", [$rootScope.activeUser._id])
        promise = $kinvey.DataStore.find( "Books", query )
        promise.then (books) ->
          $rootScope.books = books

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
            $rootScope.getUserBooks().then () ->
              loginEvent = 'loginEvent'
              $scope.$broadcast(loginEvent)
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
            $rootScope.getUserBooks().then () ->
              loginEvent = 'loginEvent'
              $scope.$broadcast(loginEvent)
              $scope.closeSignup()

      if kinveyUser
        if kinveyUser.username == "user"
          $scope.openLogin()
          return
        else 
          $rootScope.activeUser = kinveyUser
          $rootScope.getUserBooks().then () ->
            loginEvent = 'loginEvent'
            $scope.$broadcast(loginEvent)
            return
      else
        $scope.openLogin()
        return

    return
])

app.controller('ReadCtrl', [
  "$rootScope"
  "$scope"
  "$kinvey"
  "$stateParams"
  "$location"
  ($rootScope, $scope, $kinvey, $stateParams, $location) ->
    console.log 'in read ctrl'

    $scope.redirectToEdit = (editUrl) ->
      $location.path(editUrl)

    $scope.$on 'loginEvent', () ->
      add_book = {
        coverImageUrl: "img/add_book_icon.jpg"
        add_url: "add"
      }
      books_to_chunk = $scope.books
      books_to_chunk.unshift(add_book)
      $rootScope.libraryLayout = chunk(books_to_chunk, 3)
      # $rootScope.libraryLayout.unshift(add_book)
      return
    return
])

app.controller('ReviewCtrl', ($scope) ->
  console.log 'in review ctrl'
)

app.controller('PlayerCtrl', [
  "$kinvey"
  "$location"
  "$scope"
  "$stateParams"
  "$rootScope"
  "$ionicSlideBoxDelegate"
  "$http"
  ($kinvey, $location, $scope, $stateParams, $rootScope, $ionicSlideBoxDelegate, $http) ->
    pageQuery = new $kinvey.Query()    
    pageQuery.equalTo('bookId', $stateParams.bookId)
    bookPromise = $kinvey.DataStore.get("Books", $stateParams.bookId)
    bookPromise.then (book) ->
      $scope.book = book
      promise = $kinvey.DataStore.find( "Pages", pageQuery )
      promise.then (pages) ->
        book_display_data = {
          image : {
            _downloadURL: book.coverImageUrl
          }
          text : book.title + " by " + book.author
        }
        pages.unshift(book_display_data)
        $scope.pages = pages
        $ionicSlideBoxDelegate.update()
        promise = $kinvey.DataStore.get('Languages', $rootScope.activeUser.language)
        promise.then ( translationLanguage ) ->
          $scope.translationLanguage = translationLanguage

    $scope.currentSlide = 0
    $scope.playing = false

    playUtterance = new SpeechSynthesisUtterance
    defineUtterance1 = new SpeechSynthesisUtterance
    defineUtterance2 = new SpeechSynthesisUtterance
    
    playUtterance.onend = ->
      $scope.$apply ->
        $scope.playing = false
        return
      return
    
    playUtterance.onpause = ->
      return

    defineUtterance1.onend = ->
      speechSynthesis.speak defineUtterance2
      return

    $scope.slideHasChanged = (newSlide) ->
      $scope.currentSlide = newSlide
      return

    $scope.slideTo = (slideNum) ->
      speechSynthesis.cancel()
      $scope.playing = false
      $ionicSlideBoxDelegate.slide(slideNum)

    $scope.slidePrevious = ->
      speechSynthesis.cancel()
      $scope.playing = false
      $ionicSlideBoxDelegate.previous()
      return

    $scope.slideNext = ->
      speechSynthesis.cancel()
      $scope.playing = false
      $ionicSlideBoxDelegate.next()
      return

    $scope.speak = (text, lang) ->
      $scope.playing = true
      if speechSynthesis.speaking == true
        speechSynthesis.resume()
      else
        playUtterance.text = text
        playUtterance.lang = lang
        playUtterance.localService = true
        speechSynthesis.speak playUtterance
      return

    $scope.pause = ->
      speechSynthesis.cancel()
      $scope.playing = false
      return

    $scope.endBook = ->
      speechSynthesis.cancel()
      $scope.playing = false
      return

    $scope.define = (word) ->
      selected_word = word.trim().replace(/["\.,-\/#!$%\^&\*;:{}=\-_`~()]/g, "")
      link = "https://translation-app.herokuapp.com/api/en/" + $scope.translationLanguage._id + "/" + selected_word
      $http.get(link).success((translated_word, status, headers, config) ->
        
        $scope.selected_word = selected_word
        $scope.translated_word = translated_word

        defineUtterance1.text = $scope.selected_word
        defineUtterance1.lang = "en"
        defineUtterance1.localService = true

        defineUtterance2.text = $scope.translated_word
        defineUtterance2.lang = $scope.translationLanguage._id
        defineUtterance2.localService = true

        speechSynthesis.speak defineUtterance1

        return
      ).error (data, status, headers, config) ->
        'error'
      return

    return
])

app.controller('SettingsCtrl', [
  "$ionicHistory"
  "$scope"
  "$kinvey"
  "$rootScope"
  "$ionicPopup"
  ($ionicHistory, $scope, $kinvey, $rootScope, $ionicPopup) ->
    promise = $kinvey.DataStore.find('Languages')
    promise.then ( listOfLanguages ) ->
      $scope.listOfLanguages = listOfLanguages
      return
    $scope.goBack = ->
      $ionicHistory.goBack()
      return
    $scope.updateUser = ->
      promise = $kinvey.User.update($rootScope.activeUser)
      promise.then () ->
        alertPopup = $ionicPopup.alert(
          title: 'SAVED')
        return
    return
])


app.controller('PracticeCtrl', [
  "$ionicHistory"
  "$scope"
  "$kinvey"
  "$rootScope"
  "$ionicPopup"
  ($ionicHistory, $scope, $kinvey, $rootScope, $ionicPopup) ->
    $scope.goBack = ->
      $ionicHistory.goBack()
      return
      # Add stuff here
])

app.controller('AddCtrl', [
  "$rootScope"
  "$scope"
  "Camera"
  "uploadContent"
  "$ionicHistory"
  "Library"
  ($rootScope, $scope, Camera, uploadContent, $ionicHistory, Library) ->
    $scope.book = {}
    imageStr = ""

    $scope.goBack = ->
      $rootScope.getUserBooks().then () ->
        $rootScope.libraryLayout = Library.getShelf($rootScope.books)
        $ionicHistory.goBack()

    $scope.getPhoto = ->

      options = {
        quality: 50
        destinationType: navigator.camera.DestinationType.DATA_URL
        encodingType: navigator.camera.EncodingType.JPEG
      }

      Camera.getPicture(options).then ((imageStr) ->
        $scope.book.image = "data:image/jpeg;base64," + imageStr
        $scope.book.imageBlob = dataURItoBlob($scope.book.image)

        return
      ), ((err) ->
        console.err err
        return
      )
      return

    $scope.addBook = ->

      imgBlob = $scope.book.imageBlob

      uploadContent.uploadFile({"image": imgBlob, "size": imgBlob.size}).then ((fileInfo) ->
        data = {
          title : $scope.book.title
          author : $scope.book.author
          coverImageFile : fileInfo
          sharedWith: [$rootScope.activeUser._id]
        }
        uploadContent.uploadModel("Books", data).then (uploaded_file) ->
          return
      ), ((err) ->
        console.log err
      )
      return
])

app.controller('EditBookCtrl', [
  "$ionicHistory"
  "$scope"
  "$kinvey"
  "$rootScope"
  "$stateParams"
  "Camera"
  "uploadContent"
  "$location"
  "$state"
  "Library"
  ($ionicHistory, $scope, $kinvey, $rootScope, $stateParams, Camera, uploadContent, $location, $state, Library) ->
    console.log 'in edit book ctrl'
    pageQuery = new $kinvey.Query()    
    pageQuery.equalTo('bookId', $stateParams.bookId)
    bookPromise = $kinvey.DataStore.get("Books", $stateParams.bookId)
    bookPromise.then (book) ->
      $scope.book = book
      pageQuery = new $kinvey.Query()    
      pageQuery.equalTo('bookId', $stateParams.bookId)
      promise = $kinvey.DataStore.find( "Pages", pageQuery )
      promise.then (pages) ->
        $scope.pages = pages
        return

    $scope.getPhoto = ->

      options = {
        quality: 50
        destinationType: navigator.camera.DestinationType.DATA_URL
        encodingType: navigator.camera.EncodingType.JPEG
      }

      Camera.getPicture(options).then ((imageStr) ->
        $scope.book.image = "data:image/jpeg;base64," + imageStr
        $scope.book.imageBlob = dataURItoBlob($scope.book.image)

        return
      ), ((err) ->
        console.err err
        return
      )
      return

    $scope.goBack = ->
      $rootScope.getUserBooks().then () ->
        $rootScope.libraryLayout = Library.getShelf($rootScope.books)
        $ionicHistory.goBack()

    $scope.updateBook = ->

      if $scope.book.imageBlob
        imgBlob = $scope.book.imageBlob

      delete $scope.book.image
      delete $scope.book.imageBlob

      if imgBlob
        uploadContent.uploadFile({"image": imgBlob, "size": imgBlob.size}).then ((fileInfo) ->
          $scope.book.coverImageFile = fileInfo
          uploadContent.updateModel("Books", $scope.book).then (uploaded_file) ->
            $scope.goBack()
            return
        ), ((err) ->
          console.log err
        )
        return
      
      else
        uploadContent.updateModel("Books", $scope.book).then (uploaded_file) ->
          $scope.goBack()
          return

      return

    $scope.deleteBook = ->
      uploadContent.deleteModel("Books", $scope.book._id).then () ->
        $scope.goBack()
        return
      return

])