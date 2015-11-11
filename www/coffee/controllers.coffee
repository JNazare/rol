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

parseHtmlEnteties = (str) ->
  str.replace /&#([0-9]{1,3});/gi, (match, numStr) ->
    num = parseInt(numStr, 10)
    String.fromCharCode num

guid = ->
  s4 = ->
    Math.floor((1 + Math.random()) * 0x10000).toString(16).substring 1
  s4() + s4() + '-' + s4() + '-' + s4() + '-' + s4() + '-' + s4() + s4() + s4()


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
  "$http"
  "askiiKey"
  "askiiUrl"
  "betaPassphrase"
  "$ionicLoading"
  "$analytics"
  "$ionicPopup"
  "$location"
  "$window"
  ($scope, $ionicModal, $rootScope, $timeout, $kinvey, kinveyKey, kinveySecret, $http, askiiKey, askiiUrl, betaPassphrase, $ionicLoading, $analytics, $ionicPopup, $location, $window) ->

    $rootScope.kinveyStart = ->
      promise = $kinvey.init(
        appKey: kinveyKey
        appSecret: kinveySecret
        sync:
            enable: true
      )
      promise.then (kinveyUser) ->
        return kinveyUser

    $rootScope.startLoading = ->
      $ionicLoading.show template: 'Loading...'
      $timeout (->
        $ionicLoading.hide()
        $http.get("http://askii.media.mit.edu/askii/api/v1.0/en/es/hello").success(() ->        
          return
        ).error () ->
          $rootScope.showError()
        # console.log $scope.books
        # if (!$rootScope.activeUser)
        # if !$scope.books
        #   $rootScope.showError()
      ), 5000
      return

    $rootScope.showError = ->
      $rootScope.errorMsg = "Oops! Please connect to Wifi."
      return

    $rootScope.reload = ->
      $location.path '/'
      $window.location.reload()
      return

    $rootScope.doneLoading = ->
      delete $rootScope.errorMsg
      $ionicLoading.hide()
      return

    $rootScope.startPlayLoading = ->
      $ionicLoading.show template: 'Playing'
      $timeout (->
        $ionicLoading.hide()
        return
      ), 7000
      return

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

    $ionicModal.fromTemplateUrl("templates/reset-password.html",
      scope: $scope
    ).then (forgotmodal) ->
      $scope.forgotmodal = forgotmodal
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
        first_query = new $kinvey.Query()
        second_query = new $kinvey.Query()
        first_query.contains("sharedWith", [$rootScope.activeUser._id])
        second_query.equalTo("public", true)
        promise = $kinvey.DataStore.find( "Books", first_query.or(second_query) )
        promise.then (books) ->
          for book in books
            if book._acl.creator == $rootScope.activeUser._id or $rootScope.activeUser.admin == true
              book["editable"]=true
          $rootScope.books = books

      $scope.openLogin = ->
        $analytics.eventTrack('Open - Login', {  category: 'Page View' })
        $scope.errorMessage = null
        $scope.loginmodal.show()
        $rootScope.doneLoading()
        return

      $scope.openForgotPassword = ->
        $analytics.eventTrack('Open - Forgot Password', {  category: 'Page View' })
        $scope.errorMessage = null
        $scope.forgotData = {}
        $scope.forgotmodal.show()
        $rootScope.doneLoading()
        return

      $scope.closeLogin = ->
        $scope.loginmodal.hide()
        return

      $scope.closeSignup = ->
        $scope.signupmodal.hide()
        return

      $scope.closeForgotPassword = ->
        $scope.checkEmailMessage = null
        $scope.forgotmodal.hide()
        return

      $scope.openSignup = ->
        $analytics.eventTrack('Open - Signup', {  category: 'Page View' })
        $scope.errorMessage = null
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
        $rootScope.doneLoading()

      $scope.doForgotPassword = ->
        promise = $kinvey.User.resetPassword( $scope.forgotData.username )
        promise.then ((response) ->
          $scope.checkEmailMessage = "Please check your email for the reset link."
          $scope.closeForgotPassword()
          $scope.openLogin()
          return
        ), (err) ->
          return
        return

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
          promise.then ((activeUser) ->
            $rootScope.activeUser = activeUser
            $analytics.setUsername($rootScope.activeUser._id.toString())

            $rootScope.getUserBooks().then () ->
              loginEvent = 'loginEvent'
              $scope.$broadcast(loginEvent)
              $scope.closeLogin()
              return

          ), (error) ->
            $scope.errorMessage = "Sorry! Please try again."
            return

        if $kinvey.getActiveUser()
          $kinvey.User.logout().then () ->
            logIntoKinvey()
        else
          logIntoKinvey()

      $scope.doSignup = ->
        logoutPromise = $kinvey.User.logout()
        logoutPromise.then (() ->
          formData = {
            username: $scope.signupData.username.toLowerCase()
            password: $scope.signupData.password
            email: $scope.signupData.username.toLowerCase()
            language: $scope.signupData.language._id
            speed: 1
          }
          signup_promise = $kinvey.User.signup(formData)
          signup_promise.then ((activeUser) ->
            $rootScope.activeUser = activeUser
            $analytics.setUsername($rootScope.activeUser._id.toString())
            $analytics.setUserProperties({"$name": $rootScope.activeUser.username.toString(), "$email": $rootScope.activeUser.username.toString()})
            $rootScope.getUserBooks().then () ->
              
              loginEvent = 'loginEvent'
              $scope.$broadcast(loginEvent)
              $scope.closeSignup()
              return

          ), (error) ->
            $scope.errorMessage = "Sorry! Please try again."
            return
        ), (error) ->
          $scope.errorMessage = "Sorry! Please try again."
          return

      if kinveyUser
        if kinveyUser.username == "user"
          $scope.openLogin()
          return
        else 
          $rootScope.activeUser = kinveyUser

          $analytics.setUsername($rootScope.activeUser._id.toString())

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
  "$analytics"
  ($rootScope, $scope, $kinvey, $stateParams, $location, $analytics) ->
    $rootScope.startLoading()
    $analytics.eventTrack('Open - Library', {  category: 'Page View' })
    $scope.redirectToEdit = (editUrl) ->
      $location.path(editUrl)
    $scope.$on 'loginEvent', () ->
      add_book = {
        coverImageUrl: "img/add_book_icon.jpg"
        add_url: "add"
      }
      books_to_chunk = $scope.books
      if $rootScope.activeUser.admin == true
        books_to_chunk.unshift(add_book)
      $rootScope.libraryLayout = chunk(books_to_chunk, 3)
      $rootScope.doneLoading()
      return
    return
])

app.controller('PlayerCtrl', [
  "$kinvey"
  "$location"
  "$scope"
  "$stateParams"
  "$rootScope"
  "$ionicSlideBoxDelegate"
  "$http"
  "askiiUrl"
  "askiiKey"
  "$analytics"
  "$state"
  "$ionicPopup"
  "$window",
  "$ionicScrollDelegate"
  "$timeout"
  ($kinvey, $location, $scope, $stateParams, $rootScope, $ionicSlideBoxDelegate, $http, askiiUrl, askiiKey, $analytics, $state, $ionicPopup, $window, $ionicScrollDelegate, $timeout) ->

    $rootScope.startLoading()

    # console.log $rootScope.logError
    # if $rootScope.logError == true
    #   showConnectError()

    # $rootScope.activeUser.language = $kinvey.getActiveUser().language
    $scope.numPagesShown = 5
    $scope.beginningIndex = 0
    $scope.endIndex = $scope.beginningIndex + $scope.numPagesShown

    pageQuery = new $kinvey.Query()    
    pageQuery.equalTo('bookId', $stateParams.bookId)
    pageQuery.ascending('pageNumber')
    bookPromise = $kinvey.DataStore.get("Books", $stateParams.bookId)
    bookPromise.then ((book) ->
      $scope.book = book
      promise = $kinvey.DataStore.find( "Pages", pageQuery )
      promise.then (pages) ->
        book_display_data = {
          image : {
            _downloadURL: book.coverImageFile._downloadURL
          }
          text : book.title + " by " + book.author
        }
        pages.unshift(book_display_data)
        $scope.pages = pages
        $ionicSlideBoxDelegate.update()
        promise = $kinvey.DataStore.get('Languages', $rootScope.activeUser.language)
        $analytics.eventTrack('Open - Player for ' + book.title, {  category: 'Page View' })
        promise.then ( translationLanguage ) ->
          $scope.translationLanguage = translationLanguage
          adjustScrollHeight( $ionicSlideBoxDelegate.currentIndex() )
          $rootScope.doneLoading()
    ), (err) ->
      showConnectError()

    showConnectError = ->
      $rootScope.doneLoading()
      $rootScope.showError()

    $scope.refreshPlay = ->
      delete $rootScope.errorMsg
      $location.path '/'

    $scope.currentSlide = 0
    $scope.playing = false
    $scope.selected_word = null
    $scope.translated_word = null

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
      # speechSynthesis.speak defineUtterance2
      $rootScope.doneLoading()
      return

    $scope.getSlideClass = (ct) ->
      return "slide" + ct

    adjustScrollHeight = (newSlide) ->
      height = angular.element(".slide"+newSlide).css("height")
      angular.element(".scroll").css("height", height)
      angular.element(".slider").css("height", height)

    $scope.slideHasChanged = (newSlide) ->
      $scope.currentSlide = newSlide
      if newSlide <= $scope.beginningIndex
        $scope.beginningIndex = $scope.beginningIndex  - $scope.numPagesShown
        $scope.endIndex = $scope.endIndex - $scope.numPagesShown
      if newSlide >= $scope.endIndex
        $scope.beginningIndex = $scope.beginningIndex + $scope.numPagesShown
        $scope.endIndex = $scope.endIndex + $scope.numPagesShown
      $ionicScrollDelegate.scrollTop()
      $ionicSlideBoxDelegate.update()
      adjustScrollHeight(newSlide)
      # height = angular.element(".slide"+newSlide).css("height")
      # angular.element(".scroll").css("height", height)
      # angular.element(".slider").css("height", height)
      return

    $scope.slideTo = (slideNum) ->
      speechSynthesis.cancel()
      $scope.playing = false
      if $scope.currentSlide == slideNum
        imageUrl = $scope.pages[slideNum].image._downloadURL
        alertPopup = $ionicPopup.alert(
          title: ''
          template: '<img src="'+imageUrl+'" width="100%">')
        return
      else
        $ionicSlideBoxDelegate.slide(slideNum)
        $scope.beginningIndex = slideNum - (slideNum % $scope.numPagesShown)
        $scope.endIndex = $scope.beginningIndex + $scope.numPagesShown
        $ionicScrollDelegate.scrollTop()
        adjustScrollHeight(slideNum)
        return

    $scope.slidePrevious = ->
      speechSynthesis.cancel()
      $scope.playing = false
      $ionicSlideBoxDelegate.previous()
      $ionicScrollDelegate.scrollTop()
      adjustScrollHeight( $ionicSlideBoxDelegate.currentIndex() )
      return

    $scope.slideNext = ->
      speechSynthesis.cancel()
      $scope.playing = false
      $ionicSlideBoxDelegate.next()
      $ionicScrollDelegate.scrollTop()
      adjustScrollHeight( $ionicSlideBoxDelegate.currentIndex() )
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
      $rootScope.errorFlag = false
      $location.path '/'
      return

    $scope.createReviewQuestion = (index) ->
      $scope.savedWord = true # hacky, fix this

      length_selected_word = $scope.selected_word.length
      fill_in_text = Array(length_selected_word).join("_")
      question_text = $scope.pages[index].text.replace($scope.selected_word, fill_in_text)
      answer_text = $scope.selected_word
      hint_text = $scope.translated_word

      new_vocab_entry = {
        "question": question_text
        "hint": hint_text
        "answer": answer_text
        "book": $scope.book.title
        "bookImage": $scope.book.coverImageFile._downloadURL
        "_id": guid()
      }

      if $rootScope.activeUser.vocabulary
        $rootScope.activeUser.vocabulary.push(new_vocab_entry)
      else
        $rootScope.activeUser.vocabulary = [new_vocab_entry]
      
      promise = $kinvey.User.update($rootScope.activeUser)
      promise.then ((user) ->
        return
      ), (err) ->
        console.log err
        return

      return

    $scope.define = (word, pageIndex, wordIndex, paragraphIndex) ->
      $rootScope.startPlayLoading()
      $scope.savedWord = false # hacky, fix this

      $scope.pageIndex = pageIndex
      $scope.wordIndex = wordIndex
      $scope.paragraphIndex = paragraphIndex
      $scope.unformatted_selected_word = word
      $scope.selected_word = word.trim().replace(/["\.',-\/#!$%\^&\*;:{}=\-_`~()]/g, "")

      defineUtterance1.text = $scope.selected_word #$scope.translated_word
      defineUtterance1.lang = "en-US" #$scope.translationLanguage.voice
      defineUtterance1.localService = true
      speechSynthesis.speak defineUtterance1

      link = askiiUrl + "/en/" + $scope.translationLanguage._id + "/" + $scope.selected_word
      $http.get(link).success((translated_word, status, headers, config) ->        
        $scope.translated_word = parseHtmlEnteties(translated_word)
        return
      ).error (data, status, headers, config) ->
        $scope.translated_word = ""
        alertPopup = $ionicPopup.alert(
          title: 'Oops!'
          template: 'Please connect to the Wifi.')
      return

    $scope.replay_definition = (english_word, translated_word) ->

      if $scope.selected_word and $scope.translated_word
        $rootScope.startPlayLoading()

        defineUtterance1.text = $scope.selected_word #translated_word
        defineUtterance1.lang = "en-US" #$scope.translationLanguage.voice
        defineUtterance1.localService = true

        speechSynthesis.speak defineUtterance1

      else
        notSelectedUtterance = new SpeechSynthesisUtterance
        notSelectedUtterance.text = 'Click on a word to translate'
        notSelectedUtterance.lang = "en-US"
        notSelectedUtterance.localService = true

        speechSynthesis.speak notSelectedUtterance

      return


    return
])

app.controller('SettingsCtrl', [
  "$ionicHistory"
  "$scope"
  "$kinvey"
  "$rootScope"
  "$ionicPopup"
  "$analytics"
  "$state"
  "$location"
  "$window"
  ($ionicHistory, $scope, $kinvey, $rootScope, $ionicPopup, $analytics, $state, $location, $window) ->
    $analytics.eventTrack('Open - Settings', {  category: 'Page View' })
    promise = $kinvey.DataStore.find('Languages')
    promise.then ( listOfLanguages ) ->
      $scope.listOfLanguages = listOfLanguages
      return
    $scope.goBack = ->
      $ionicHistory.goBack()
      return
    $scope.resetPassword = (username) ->
      promise = $kinvey.User.resetPassword(username)
      promise.then ((response) ->
        return
      ), (err) ->
        return
      return
    $scope.updateUser = ->
      promise = $kinvey.User.update($rootScope.activeUser)
      promise.then (updatedUser) ->
        $rootScope.activeUser.language = updatedUser.language
        alertPopup = $ionicPopup.alert(title: 'SAVED')
        return
    return
])

app.controller 'EditCtrl', ($scope) ->
  $scope.settings = enableFriends: true
  return


app.controller('ReviewCtrl', [
  "$scope"
  "$ionicPopup"
  "askiiUrl"
  "askiiKey"
  "$http"
  "$rootScope"
  "$kinvey"
  "$analytics"
  ($scope, $ionicPopup, askiiUrl, askiiKey, $http, $rootScope, $kinvey, $analytics) ->
    $scope.displayAll = true
    $analytics.eventTrack('Open - Review', {  category: 'Page View' })

    $scope.showPopup = (vocab) ->
      length_selected_word = vocab.answer.length
      fill_in_text = Array(length_selected_word).join("_")
      splitQuestionArray = vocab.question.split(fill_in_text)
      splitQuestionString = splitQuestionArray[0] + '<span class="english">' + vocab.answer + '</span>' + splitQuestionArray[1] 

      alertPopup = $ionicPopup.alert (
        title: "<strong>" +  vocab.answer + "</strong>"
        subTitle: "<strong>" + vocab.hint + "</strong>"
        template: splitQuestionString )
      return

    $scope.deleteQuestion = (vocab) ->
      index = $rootScope.activeUser.vocabulary.indexOf(vocab._id)
      $rootScope.activeUser.vocabulary.splice index, 1

      promise = $kinvey.User.update($rootScope.activeUser)
      promise.then ((user) ->
        return
      ), (err) ->
        console.log err
        return

      return
  ]
)

app.controller('AddCtrl', [
  "$rootScope"
  "$scope"
  "Camera"
  "uploadContent"
  "$ionicHistory"
  "Library"
  "$analytics"
  ($rootScope, $scope, Camera, uploadContent, $ionicHistory, Library, $analytics) ->

    $analytics.eventTrack('Open - Create New Book', {  category: 'Page View' })
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
  "$analytics"
  ($ionicHistory, $scope, $kinvey, $rootScope, $stateParams, Camera, uploadContent, $location, $state, Library, $analytics) ->
    $analytics.eventTrack('Open - Edit Book', {  category: 'Page View' })
    pageQuery = new $kinvey.Query()    
    pageQuery.equalTo('bookId', $stateParams.bookId)
    bookPromise = $kinvey.DataStore.get("Books", $stateParams.bookId)
    bookPromise.then (book) ->
      $scope.book = book
      pageQuery = new $kinvey.Query()    
      pageQuery.equalTo('bookId', $stateParams.bookId)
      promise = $kinvey.DataStore.find( "Pages", pageQuery )
      promise.then (pages) ->
        add_page_data = {
          image : {
            _downloadURL: "img/add_book_icon.jpg"
          }
          text : ""
        }
        pages.push(add_page_data)
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

app.controller('EditPageCtrl', [
  "$ionicHistory"
  "$scope"
  "$kinvey"
  "$rootScope"
  "$stateParams"
  "$ionicSlideBoxDelegate"
  "uploadContent"
  "Pages"
  "$analytics"
  ($ionicHistory, $scope, $kinvey, $rootScope, $stateParams, $ionicSlideBoxDelegate, uploadContent, Pages, $analytics) ->

    $analytics.eventTrack('Open - Edit Page', {  category: 'Page View' })
    $scope.currentSlide = $stateParams.pageNum
    pageQuery = new $kinvey.Query()    
    pageQuery.equalTo('bookId', $stateParams.bookId)
    bookPromise = $kinvey.DataStore.get("Books", $stateParams.bookId)
    bookPromise.then (book) ->
      $scope.book = book
      promise = $kinvey.DataStore.find( "Pages", pageQuery )
      promise.then (pages) ->
        add_page_data = {
          image : {
            _downloadURL: "img/add_book_icon.jpg"
          }
          text : ""
        }
        pages.push(add_page_data)
        $scope.pages = pages
        $ionicSlideBoxDelegate.update()
        $ionicSlideBoxDelegate.slide($stateParams.pageNum)

    $scope.goBack = ->
      $scope.pages = Pages.getPages($scope.book._id)
      $ionicHistory.goBack()
      return

    $scope.slideHasChanged = (newSlide) ->
      $ionicScrollDelegate.scrollTop()
      $scope.currentSlide = newSlide
      return

    $scope.slideTo = (slideNum) ->
      $ionicSlideBoxDelegate.slide(slideNum)

    $scope.slidePrevious = ->
      $ionicSlideBoxDelegate.previous()
      return

    $scope.slideNext = ->
      $ionicSlideBoxDelegate.next()
      return

    $scope.changeImage = (index) ->
      # lead to a popup that allows you to retake the photo - implement after refactoring
      return

    $scope.saveChanges = (index) ->
      updatedPage = $scope.pages[index]
      if index == $scope.pages.length - 1
        updatedText = updatedPage.text
        newPage = {
          "bookId": $scope.book._id
          "text": updatedText
          "pageNumber": index
        }
        uploadContent.uploadModel("Pages", newPage).then (uploaded_page) ->
          # this should probably show a "saved" alert
          return
      else
        uploadContent.updateModel("Pages", updatedPage).then (uploaded_page) ->
          # this should probably show a "saved" alert
          return
      return

])

# app.controller('TipsCtrl', [
#   "$ionicHistory"
#   "$scope"
#   "$kinvey"
#   "$rootScope"
#   "$ionicPopup"
#   "$analytics"
#   "$state"
#   "$location"
#   "$window"
#   "$sce"
#   ($ionicHistory, $scope, $kinvey, $rootScope, $ionicPopup, $analytics, $state, $location, $window, $sce) ->
#     $analytics.eventTrack('Open - Tips', {  category: 'Page View' })
#     tipsQuery = new $kinvey.Query()    
#     tipsQuery.equalTo('show', true)
#     tipsQuery.ascending('order')
#     tipsPromise = $kinvey.DataStore.find( "Tips", tipsQuery )
#     tipsPromise.then (tips) ->
#       $scope.tips = tips
#     $scope.goBack = ->
#       $ionicHistory.goBack()
#       return
#     $scope.trustSrc = (src) ->
#       $sce.trustAsResourceUrl src
#     return
# ])
