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

uniq = (a) ->
  seen = {}
  a.filter (item) ->
    if seen.hasOwnProperty(item) then false else (seen[item] = true)

uniqueObjects = (a) ->
  arr = {}
  i = 0
  while i < a.length
    arr[a[i]['answer']] = a[i]
    i++
  a = new Array
  for key of arr
    a.push arr[key]
  return a

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
  ($scope, $ionicModal, $rootScope, $timeout, $kinvey, kinveyKey, kinveySecret, $http, askiiKey, askiiUrl, betaPassphrase, $ionicLoading) ->
    
    console.log 'in app ctrl'

    $rootScope.startLoading = ->
      $ionicLoading.show template: 'Loading...'
      return

    $rootScope.doneLoading = ->
      $ionicLoading.hide()
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
        # promise = $kinvey.DataStore.find( "Books", query )
        promise = $kinvey.DataStore.find( "Books" )
        promise.then (books) ->
          for book in books
            if book._acl.creator == $rootScope.activeUser._id
              book["editable"]=true
          $rootScope.books = books

      $scope.openLogin = ->
        $scope.errorMessage = null
        $scope.loginmodal.show()
        $rootScope.doneLoading()
        return

      $scope.closeLogin = ->
        $scope.loginmodal.hide()
        return

      $scope.closeSignup = ->
        $scope.signupmodal.hide()
        return

      $scope.openSignup = ->
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
            $rootScope.getUserBooks().then () ->

              $http.get( askiiUrl+'/users/username/'+$rootScope.activeUser.username+'?key='+askiiKey ).success((data, status, headers, config) ->
                
                $rootScope.activeUser.askiiUser = data
                # this callback will be called asynchronously
                # when the response is available

                loginEvent = 'loginEvent'
                $scope.$broadcast(loginEvent)
                $scope.closeLogin()

                return
              ).error (data, status, headers, config) ->
                # called asynchronously if an error occurs
                # or server returns response with an error status.
                $scope.errorMessage = "Sorry! Please try again."
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
        if $scope.signupData.betaPassphrase == betaPassphrase
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
              $rootScope.getUserBooks().then () ->

                data = {"username": $rootScope.activeUser.email}
                $http.post( askiiUrl+'/users?key='+askiiKey, data ).success((data, status, headers, config) ->
                  
                  console.log data
                  $rootScope.activeUser.askiiUser = data
                  # this callback will be called asynchronously
                  # when the response is available

                  loginEvent = 'loginEvent'
                  $scope.$broadcast(loginEvent)
                  $scope.closeSignup()

                  return
                ).error (data, status, headers, config) ->
                  # called asynchronously if an error occurs
                  # or server returns response with an error status.
                  console.log 'wrong login'
                  $scope.errorMessage = "Sorry! Please try again."
                  return
            ), (error) ->
              $scope.errorMessage = "Sorry! Please try again."
              return
          ), (error) ->
            $scope.errorMessage = "Sorry! Please try again."
            return
        else
          $scope.errorMessage = "Sorry! Incorrect passphrase."
          return

      if kinveyUser
        if kinveyUser.username == "user"
          $scope.openLogin()
          return
        else 
          $rootScope.activeUser = kinveyUser

          $http.get( askiiUrl+'/users/username/'+$rootScope.activeUser.username+'?key='+askiiKey ).success((data, status, headers, config) ->
                
            $rootScope.activeUser.askiiUser = data
            # this callback will be called asynchronously
            # when the response is available

            $rootScope.getUserBooks().then () ->
              loginEvent = 'loginEvent'
              $scope.$broadcast(loginEvent)
              return

            return
          ).error (data, status, headers, config) ->
            # called asynchronously if an error occurs
            # or server returns response with an error status.
            $scope.openLogin()
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
    $rootScope.startLoading()
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
      $rootScope.doneLoading()
      # $rootScope.libraryLayout.unshift(add_book)
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
  ($kinvey, $location, $scope, $stateParams, $rootScope, $ionicSlideBoxDelegate, $http, askiiUrl, askiiKey) ->
    $rootScope.startLoading()
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
          $rootScope.doneLoading()

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
        console.log speechSynthesis
        console.log playUtterance
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

    $scope.createReviewQuestion = (word, index) ->
      $scope.savedWord = true # hacky, fix this

      console.log word
      console.log index
      length_selected_word = $scope.selected_word.length
      fill_in_text = Array(length_selected_word).join("_")
      question_text = $scope.pages[index].text.replace($scope.selected_word, fill_in_text)
      answer_text = $scope.selected_word.toLowerCase()
      hint_text = $scope.translated_word

      console.log $rootScope.activeUser.askiiUser

      new_question = {
        "question": question_text
        "hint": hint_text
        "answer": answer_text
        "book": $scope.book.title
        "bookImage": $scope.book.coverImageUrl
        "difficulty": 0
        "personalized": true
        "creator": $rootScope.activeUser.askiiUser.user.uri.split("/").slice(-1)[0]
      }

      $http.post( askiiUrl+'/questions?key='+askiiKey, new_question ).success((data, status, headers, config) ->
              
        console.log data
        # this callback will be called asynchronously
        # when the response is available

        return
      ).error (data, status, headers, config) ->
        # called asynchronously if an error occurs
        # or server returns response with an error status.
        return
      return

    $scope.define = (word, index) ->
      $rootScope.startLoading()
      $scope.savedWord = false # hacky, fix this

      $scope.pageIndex = index
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

        $rootScope.doneLoading()

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
  "askiiUrl"
  "askiiKey"
  "$http"
  "$rootScope"
  ($scope, $ionicPopup, askiiUrl, askiiKey, $http, $rootScope) ->
    console.log 'in review ctrl'
    $rootScope.startLoading()
    userId = $rootScope.activeUser.askiiUser.user.uri.split("/").slice(-1)[0]
    console.log userId

    $http.get( askiiUrl+'/questions?key='+askiiKey+'&creator='+userId).success((data, status, headers, config) ->
      
      console.log data
      console.log data.questions
      $scope.vocablist = data.questions
      $scope.allUniqueVocab = uniqueObjects($scope.vocablist)
      # add this to template

      organizedBooks = (allQuestions) ->
        organizedByBook = {}
        for question in allQuestions
          if question.book 
            if question.book not in Object.keys(organizedByBook)
              organizedByBook[question.book] = [question]
            else
              organizedByBook[question.book].push(question)
        for bookTitle, bookObj of organizedByBook
          organizedByBook[bookTitle] = uniqueObjects(bookObj)
        return organizedByBook

      $scope.organizedByBook = organizedBooks( $scope.vocablist )
      $rootScope.doneLoading()
      return
    ).error (data, status, headers, config) ->
      # called asynchronously if an error occurs
      # or server returns response with an error status.
      return

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
  "$stateParams"
  "$location"
  "askiiUrl"
  "askiiKey"
  "$http"
  ($ionicHistory, $scope, $kinvey, $rootScope, $ionicPopup, $stateParams, $location, askiiUrl, askiiKey, $http) ->

    findQuestionIndex = (allQuestions, nextQuestion) ->
      i = 0
      len = allQuestions.length
      while i < len
        if allQuestions[i].uri == nextQuestion.uri
          return i
        # Return as soon as the object is found
        i++
      null

    findAllRepeats = (allQuestions, nextQuestion) ->
      ct = 0
      toRemove = []
      for question in allQuestions
        if question.answer == nextQuestion.answer
          toRemove.unshift(ct)
        ct += 1
      for index in toRemove
        allQuestions.splice(index, 1)
      return allQuestions

    # 'shuffle alogithm taken from CoffeeScript Cookbook'
    shuffle = (a) ->
      i = a.length
      while --i > 0
        j = ~~(Math.random() * (i + 1)) # ~~ is a common optimization for Math.floor
        t = a[j]
        a[j] = a[i]
        a[i] = t
      return a
    
    joinAnswers = (wrongList, rightAnswer) ->
      if wrongList.length > 4
        wrongList = shuffle(wrongList).splice(0,4)
      for question in wrongList
        question["correct"] = false
      rightAnswer["correct"] = true
      wrongList.push rightAnswer
      shuffle(wrongList)
      return wrongList

    $scope.goBack = ->
      $ionicHistory.goBack()
      return

    # 'for interacting with progress bar (blocks)'
    $rootScope.startLoading()
    $scope.questionNum = $stateParams.practiceNum
    $scope.blockList = [0,1,2,3,4,5,6,7,8,9]
    userId = $rootScope.activeUser.askiiUser.user.uri.split("/").slice(-1)[0]

    $http.get( askiiUrl+'/questions?creator='+userId+'&key='+askiiKey ).success((data, status, headers, config) ->
      
      # console.log data

      $scope.allQuestions = data["questions"]
      # console.log $scope.allQuestions
      
      data = {"count": $stateParams.practiceNum.toString() }

      $http.post( askiiUrl+'/next/'+userId+'?creator='+userId+'&key='+askiiKey, data ).success((data, status, headers, config) ->
        
        $scope.nextQuestion = data
        length_selected_word = $scope.nextQuestion.answer.length
        fill_in_text = Array(length_selected_word).join("_")
        $scope.nextQuestion["splitQuestion"] = $scope.nextQuestion.question.split(fill_in_text)
        toRemove = findQuestionIndex($scope.allQuestions, $scope.nextQuestion)
        $scope.allQuestions.splice(toRemove, 1)
        $scope.allQuestions = findAllRepeats($scope.allQuestions, $scope.nextQuestion)
        $scope.allQuestions = uniqueObjects( $scope.allQuestions )
        $scope.possibleAnswers = joinAnswers($scope.allQuestions, $scope.nextQuestion)
        $rootScope.doneLoading()
        return
        
      ).error (data, status, headers, config) ->
        # called asynchronously if an error occurs
        # or server returns response with an error status.
        return

      return

    ).error (data, status, headers, config) ->
      # called asynchronously if an error occurs
      # or server returns response with an error status.
      return

    # 'if select incorrect, popup says try again'
    # 'if select correct, popup takes you to next question. Stop after 10 questions'
    $scope.showResult = (question) ->
      console.log 'in showResult function'
      if question.correct

        #save question back to askii here
        userId = $rootScope.activeUser.askiiUser.user.uri.split("/").slice(-1)[0]
        questionId = $scope.nextQuestion.uri.split("/").slice(-1)[0]
        data = {"answer": "1"}
        $http.post( askiiUrl+'/users/'+userId+'/'+questionId+'?key='+askiiKey, data ).success((data, status, headers, config) ->
          console.log data
          return
        ).error (data, status, headers, config) ->
          return


        nextPageNum = parseInt($stateParams.practiceNum)
        nextPageNum += 1

        if nextPageNum > 9
          alertPopup = $ionicPopup.alert (
            title: "PRACTICE DONE!"
            template: "Congratulations!"
            buttons: [
              {
                text: 'Continue'
                onTap: () ->
                  $location.path("/practice/0")
              },
              {
                text: 'End'
                onTap: () ->
                  $location.path("/library")
              }
            ])

        else
          correctPopup = $ionicPopup.show (
            title: "Good Job!"
            template: question.answer + ' = ' + question.hint
            buttons: [{
              text: 'Next'
              type: 'button-balanced'
              onTap: () ->
                for word in $scope.possibleAnswers
                  delete word["clicked"]
                $location.path("/practice/" + nextPageNum.toString())
            }])
      else
        # need a listener here?
        alertPopup = $ionicPopup.alert (
          title: "Try again!"
          template: question.answer + ' = ' + question.hint)
  ]
)
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
  ($ionicHistory, $scope, $kinvey, $rootScope, $stateParams, $ionicSlideBoxDelegate, uploadContent, Pages) ->

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
      console.log updatedPage
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
