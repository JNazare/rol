chunk = (arr, size) ->
  newArr = []
  i = 0
  while i < arr.length
    newArr.push arr.slice(i, i + size)
    i += size
  newArr

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
  ($scope, $ionicModal, $rootScope, $timeout, $kinvey) ->
    
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
            getUserBooks().then () ->
              loginEvent = 'loginEvent'
              $scope.$broadcast(loginEvent)
              $scope.closeSignup()

      if kinveyUser
        if kinveyUser.username == "user"
          $scope.openLogin()
          return
        else 
          $rootScope.activeUser = kinveyUser
          getUserBooks().then () ->
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
  "kinveyFactory"
  ($rootScope, $scope, $kinvey, $stateParams, kinveyFactory) ->
    console.log 'in read ctrl'

    $scope.$on 'loginEvent', () ->
      add_book = {
        coverImageUrl: "img/add_book_icon.jpg"
        add_url: "tab/edit"
      }
      books_to_chunk = $scope.books
      books_to_chunk.unshift(add_book)
      $rootScope.libraryLayout = chunk(books_to_chunk, 3)
      # $rootScope.libraryLayout.unshift(add_book)
      return
    return
])

app.controller('PlayerCtrl', [
  "$kinvey"
  "$location"
  "$scope"
  "$stateParams"
  "kinveyFactory"
  "$rootScope"
  "$ionicSlideBoxDelegate"
  "$http"
  ($kinvey, $location, $scope, $stateParams, kinveyFactory, $rootScope, $ionicSlideBoxDelegate, $http) ->
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

app.controller 'EditCtrl', ($scope) ->
  $scope.settings = enableFriends: true
  return


# ReviewCtrl & PracticeCtrl - edits by Emily

app.controller('ReviewCtrl', [
  "$scope"
  "$ionicPopup"
  ($scope, $ionicPopup) ->
    console.log 'in review ctrl'
    
    $scope.vocablist = [
      {
        english: 'ROAD'
        defn: 'camino'
        book: 'ginger'
      },
      {
        english: 'LOSE'
        defn: 'perder'
        book: 'hansel'
      },
      {
        english: 'PLACE'
        defn: 'lugar'
        book: 'hansel'
      },
      {
        english: 'OUTSIDE'
        defn: 'afuera'
        book: 'hansel'
      },
      {
        english: 'RUN'
        defn: 'correr'
        book: 'ginger'
      }
    ]
    
    # 'creates specific list according to book (potentially not a scope variable)'
    $scope.bookList = (title, biglist) ->
      thisList = []
      for word in biglist
        if (title is word.book)
          thisList.push word
      return thisList

    $scope.hanselList = $scope.bookList("hansel", $scope.vocablist)
    $scope.gingerList = $scope.bookList("ginger", $scope.vocablist)

    $scope.showPopup = (vocab) ->
      console.log 'in showPopup function' + vocab
      alertPopup = $ionicPopup.alert (
        title: vocab.english
        subTitle: vocab.defn
        template: '(sentence in context)')
      return
  ]
)

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
      
    $scope.answer = {
      eng: 'milk'
      correct: true
      defn: 'leche'
    }
    
    wrongAnswers = [
      {
        eng: 'napkin'
        correct: false
        defn: 'servilleta'
      },
      {
        eng: 'lose'
        correct: false
        defn: 'perder'
      },
      {
        eng: 'place'
        correct: false
        defn: 'lugar'
      },
      {
        eng: 'outside'
        correct: false
        defn: 'afuera'
      }
    ]

    # 'shuffle alogithm taken from CoffeeScript Cookbook'
    shuffle = (a) ->
      i = a.length
      while --i > 0
        j = ~~(Math.random() * (i + 1)) # ~~ is a common optimization for Math.floor
        t = a[j]
        a[j] = a[i]
        a[i] = t
      a
    
    joinAnswers = (wrongList, rightAnswer) ->
      wrongList.push rightAnswer
      shuffle(wrongList)
      return wrongList

    $scope.possibleAnswers = joinAnswers(wrongAnswers, $scope.answer)

    # 'Popup to say whether selected word is correct or not'
    $scope.showResult = (word) ->
      console.log 'in showResult function'
      if word.correct
        alertPopup = $ionicPopup.alert (
          title: "Good Job!"
          template: word.eng + ' = ' + word.defn)
      else
        alertPopup = $ionicPopup.alert (
          title: "Try again!"
          template: word.eng + ' = ' + word.defn)
      
    # 'when clicked wrong answer, variable clickedWrong = true' 
    # 'and ng-class uses class="wrong-answer" to make div opaque'
    # $scope.makeOpaque = (word)->
    #   newWord = word.concat clickedWrong:true
    #   return newWord
  ]
)
