angular
  # .module 'video-background', ['ngVidBg']
  

  .module 'angular', [
    # 'video-background',
    'ngVidBg',
    'ngRoute', 
    'ngAnimate', 
    'ngSanitize',  
    'firebase', 
    'templates',
    'ui.bootstrap.carousel' ,
    'ui.bootstrap.tpls',
    'ui.calendar', 
    'mgcrea.ngStrap.affix', 
    'mgcrea.ngStrap.helpers.dimensions',
    # 'ui.mask',
    'ui.bootstrap.typeahead',
    'ui.bootstrap.tabs',
    'ui.bootstrap.progressbar',
    'ui.bootstrap.dropdown',
    'ui.bootstrap.datepicker',
    'ui.bootstrap.collapse',
    'ui.bootstrap.buttons',
    'ui.bootstrap.accordion',
    'mgcrea.ngStrap.popover',
    'mgcrea.ngStrap.tooltip', 
    'mgcrea.ngStrap.modal', 
    'mgcrea.ngStrap.navbar', 
    'mgcrea.ngStrap.alert', 
    'angulartics', 'angulartics.google.analytics', 'angulartics.scroll',
    # or rename with gulp-ng-annotate to solve conflict
    # https://github.com/mgcrea/angular-strap/issues/521 
    # 'twilio-client-js'
    # 'angularFileUpload', 
  ]
  .config ($routeProvider, $httpProvider, $locationProvider) ->
    $locationProvider.html5Mode(false)

    $routeProvider
      .when '/inserted',  
        templateUrl: "main/inserted.html"
        controller: "HomeCtrl"
      .when '/',
        templateUrl: "main/home.html"
        controller: "HomeCtrl"
      .when '/login',
        templateUrl: "main/auth.html"
        controller: "LoginCtrl"
        controllerAs: 'login'
      .when '/contact',
        templateUrl: "main/contact.html"
        controller: "HomeCtrl"

      .when '/profile/:userId',
        templateUrl: "main/profile.html"
        controller: "ProfileCtrl"

      .otherwise
        redirectTo: '/'
  .constant('FIREBASE_URL', "https://alohadrycleaners.firebaseio.com/")
  .factory('ENVIROMENT', ($location) ->
    if $location.host() is "localhost"
      # return 'http://localhost:9000/'
      return 'http://d744f9c.ngrok.com/'
    else
      return 'https://alohadrycleaners.herokuapp.com/'
    
  )
  .run ($rootScope, $routeParams, $location, $anchorScroll, Auth) ->   

    $rootScope.$on '$routeChangeError', (event, next, previous, error) ->
      if error is "AUTH_REQUIRED"
        console.log event, next, previous, error
        $location.path "/login"
 
    
  .factory "Requests", (FIREBASE_URL, $firebase) ->
    ref = new Firebase(FIREBASE_URL)
    $firebase(ref.child("requests"))

  .factory "Claim", (FIREBASE_URL, $firebase) ->
    ref = new Firebase(FIREBASE_URL)
    $firebase(ref.child("claim"))

  .factory "Auth", ($modal, Requests, Claim, $firebase, FIREBASE_URL, $firebaseAuth, $rootScope, $timeout, $location) ->
    Auth =
      user: null
      createProfile: (user) ->
        profileData =
          # email: user[user.provider].email or ''
          md5_hash: user.md5_hash or ''
          roleValue: 10
        $firebase(ref.child('user_rooms').child(user.uid)).$set(user.uid, true)
        profileRef = $firebase(ref.child('profile').child(user.uid))
        if user.provider is 'twilio'
          phones = {}
          phones[user.auth.phone] = true
          profileRef.$update('phones', phones)
          
        angular.extend(profileData, $location.search())
        return profileRef.$update(profileData)
      requestCode: (phone) ->
        Requests.$set(phone, {uid: $rootScope.user.uid, phone: phone})

      confirmPhone: (code, phone) ->
        Claim.$set(phone, {uid: $rootScope.user.uid, phone: phone, code: code}) unless !code?

    ref = new Firebase(FIREBASE_URL)
    angular.extend(Auth, $firebaseAuth(ref))

    Auth.$onAuth (user) ->
      loginModal = $modal({template: 'main/modalLogin.html', show: false})
      if user
        Auth.user = {}
        angular.copy(user, Auth.user)
        Auth.user.profile = $firebase(ref.child('profile').child(Auth.user.uid)).$asObject()
        $rootScope.user = Auth.user
        # ref.child('profile/'+Auth.user.uid+'/online').set(true)
        # ref.child('profile/'+Auth.user.uid+'/online').onDisconnect().set(Firebase.ServerValue.TIMESTAMP)
        # ref.child('profile/'+Auth.user.uid+'/connections').push(true)
        # ref.child('profile/'+Auth.user.uid+'/connections').onDisconnect().remove()
        # ref.child('profile/'+Auth.user.uid+'/connections/lastDisconnect').onDisconnect().set(Firebase.ServerValue.TIMESTAMP)

      else
        if Auth.user and Auth.user.profile
          Auth.user.profile.$destroy()
        angular.copy({}, Auth.user)
        $rootScope.user = Auth.user



      # ref.child('.info/connected').on 'value', (snap) ->
      #   if snap.val() is true
      #     user = Auth.user.uid or 'unknown'
      #     ref.child('connections').push(user)
      #     ref.child('connections').onDisconnect().remove()

    return Auth




  .factory "Projects", (FIREBASE_URL, $firebase, $q) ->
    ref = new Firebase(FIREBASE_URL)
    projects = $firebase(ref.child('projects')).$asArray()
    Projects = 
      all: projects
      get: (projectId) ->
        return {} if projectId is true
        $firebase(ref.child('projects').child(projectId)).$asObject()
      create: (project) ->
        projects.$add(project)
      save: (project) ->
        projects.$save().then ->
          $firebase(ref.child('user_projects').child(project.creatorUID)).$push(projectRef.name())



  .factory "Profile", (FIREBASE_URL, $firebase, Projects, $q) ->
    ref = new Firebase(FIREBASE_URL)
    profile = (userId) ->
      sync: $firebase(ref.child("profile").child(userId))
      get: () ->
        $firebase(ref.child("profile").child(userId)).$asObject()
      # add: (userId) ->
      #   $firebase(ref.child("profile").child(userId))
      getProjects: () ->
        defer = $q.defer()
        $firebase(ref.child("user_projects").child(userId)).$asArray().$loaded().then (data) ->
          projects = {}
          i = 0

          while i < data.length
      #       value = data[i].$value 
            value = data[i].$id 
            projects[value] = Projects.get(value)
            i++
          defer.resolve projects
          return

        defer.promise
    profile


  .directive "messages", (FIREBASE_URL, $modal, Messages, $routeParams, Auth, $firebase, $timeout, $rootScope, $alert, $location) ->
    restrict: "E"
    templateUrl: 'main/messages.html'
    controller: ($scope)->
      loadProject = ->
        ref = new Firebase(FIREBASE_URL+"/projects").child($routeParams.requestId)
        $scope.project = $firebase(ref).$asObject()
        # $scope.cartItems = $firebase(ref.child('cartItems')).$asObject()
        # $scope.cartItems.$loaded().then (cartItems) ->
        #   unless cartItems.labor
        #     angular.extend($scope.cartItems, $rootScope.ProjectExample)

      if $routeParams.requestId is "new"
        ref = new Firebase(FIREBASE_URL+"/projects")
        $firebase(ref).$push().then (ref) ->
          search = $location.search()
          $location.url('/request/'+ref.key())
          $location.replace()
          $location.search(search)
          loadProject()
      else
        loadProject()

      $scope.newMessage = {}
      $scope.messages = {}
      $scope.sending = false

      loginModal = $modal({template: 'main/modalLogin.html', show: false})

      console.log $routeParams.requestId

      Auth.$onAuth (user) ->
        if user
          loginModal.$promise.then(loginModal.hide)
          $scope.messages = Messages(user.uid+"/"+$scope.provider.phone).get()
          
        $scope.addMessage = (newMessage) ->
          if !Auth.user
            loginModal.$promise.then(loginModal.show)
          else
            return  unless newMessage.text.trim().length and $scope.sending is false
            newMessage.sent = false
            newMessage.type = 'web' # determine from uid
            newMessage.timestamp = Firebase.ServerValue.TIMESTAMP
            newMessage.from = user.uid #change to sender
            # $scope.messages.$add(newMessage).then () ->
            Messages(user.uid+"/"+$scope.provider.phone).create(newMessage).then ->
              $scope.sending = true
              $timeout ->
                $scope.sending = false
              , 5000
              $scope.newMessage = {}

      return
    link: (scope, element, attrs, ctrl) ->
      scope.toggle = (index) ->
        console.log index
      return


  .factory "Messages", (FIREBASE_URL, $firebase, $q) ->
    ref = new Firebase(FIREBASE_URL)
    # messages = $firebase(ref.child('messages').child(senderId)).$asArray()
    Messages = (senderId) ->
      # all: $firebase(ref.child('messages').child(senderId)).$asArray()
      create: (message) ->
        $firebase(ref.child('messages').child(senderId)).$asArray().$add(message)
        # .then (messageRef) ->
        #   $firebase(ref.child('user_messages').child(message.creatorUID)).$push(messageRef.name())
      get: () ->
        $firebase(ref.child('messages').child(senderId)).$asArray()
      # get: (postId) ->
      #   $firebase(ref.child('messages').child(postId)).$asObject()
      # comments: (postId) ->
      #   $firebase(ref.child('comments').child(postId)).$asArray()

  
  .controller 'mainCtrl', ($scope) ->    
    $scope.resources = [
      'https://0.s3.envato.com/h264-video-previews/97f8b5a9-4281-4fca-8e95-160d70d575bb/8616795.mp4',



      # 'http://techslides.com/demos/sample-videos/small.webm'
      # '*.ogv',
      # '*.mp4',
      # '*.swf'
    ]
    $scope.poster = 'http://placehold.it/2000&text=you%20may%20want%20to%20have%20a%20poster'
    $scope.fullScreen = true
    $scope.muted = true
    $scope.zIndex = '-1'


  .controller 'LoginCtrl', (Requests, $http, $scope, Auth, $location, ENVIROMENT) ->    
    $scope.auth = Auth
    @authRequestCode = (phone) =>
      Requests.$set(phone, {uid: phone, phone: phone})
    @authWithPhone = (phone, code) =>
      $http.get(ENVIROMENT+"api/twilio/fbtoken?phone="+phone+"&code="+code)
      .error (error) ->
        console.log error
      .success (token) ->
        Auth.$authWithCustomToken(token).then (authData) ->
          console.log authData
          Auth.createProfile(authData)
        .catch (error) ->
          console.log error
        
        
    # $location.path '/' if $scope.user
    # @email = "user@email.com"
    # @password = "password"

    @createUser = () =>
      Auth.$createUser(@email, @password)
      .then () =>
        console.log("User created successfully!")
        @authWithPassword()
      , (error) =>
        @error = error.toString()


    @authWithPassword = =>
      Auth.$authWithPassword {email: @email, password: @password}
      .then (authData) =>
        console.log("Logged in as:", authData.uid)

        Auth.createProfile(authData)
        # $location.path "/"
      .catch (error)=>
        console.error("Error: ", error)
        if error.code is "INVALID_USER"
          @createUser()
        else
          @error = error.toString()
    return


  .controller "HomeCtrl", ($timeout, $popover, Auth, $scope, $routeParams, Profile, $firebase, FIREBASE_URL) ->
    ref = new Firebase(FIREBASE_URL)
    $scope.data = {}

    $scope.sending = false
    $scope.sendForm = (data) ->
      return  unless data.message.trim().length and $scope.sending is false
      data.timestamp = Firebase.ServerValue.TIMESTAMP
      $firebase(ref.child("contactForms")).$push(data)
      .then ->
        $scope.sending = true
        $timeout ->
          $scope.sending = false
        , 5000
        $scope.data = {}

    return
  .controller "ProfileCtrl", ($popover, Auth, $scope, $routeParams, Profile, $firebase, FIREBASE_URL) ->
    uid = $routeParams.userId
    $scope.userId = $routeParams.userId
    $scope.profile = Profile(uid).get()
    Profile(uid).getProjects().then (projects) ->
      $scope.projects = projects
      return

    ref = new Firebase(FIREBASE_URL)
    $scope.addPhone = (phone) ->
      return if phone.trim() is ''
      # Profile(uid).sync.$update('phones',{'+12245552345': false})
      phone = '+1'+phone
      Auth.requestCode(phone) unless Auth.user.roleValue >= 20
      $firebase(ref.child("profile").child(uid).child('phones')).$set(phone, false).then ->
        $scope.newPhone = ''

    escapeEmailAddress = (email) ->
      return false  unless email      
      # Replace '.' (not allowed in a Firebase key) with ',' (not allowed in an email address)
      email = email.toLowerCase()
      email = email.replace(/\./g, ",")
      email
    $scope.addEmail = (email) ->
      return if email.trim() is ''
      # Profile(uid).sync.$update('emails',{'foo@email,com': false})
      $firebase(ref.child("profile").child(uid).child('emails')).$set(escapeEmailAddress(email), false).then ->
        $scope.newEmail = ''

    $scope.addAddress = (address) ->
      $firebase(ref.child("profile").child(uid).child('addresses')).$push(address)
    $scope.remove = (obj, key) ->
      delete obj[key]

    # comfirm-phone-popover:
    $scope.confirmPhone = (code, phone) ->
      Auth.confirmPhone(code, phone)

    return









  # use to prevent ngAnimate conflict with slider
  .directive 'disableNgAnimate', ['$animate', ($animate)->
    restrict: 'A'
    link: (scope, element)-> $animate.enabled false, element
  ]

  # from angular-ui 
  .controller "TypeaheadCtrl", ($scope, $http) ->
    $scope.selected = undefined
    $scope.asyncSelected = undefined
    
    # Any function returning a promise object can be used to load values asynchronously
    $scope.getLocation = (val) ->
      $http.get("http://maps.googleapis.com/maps/api/geocode/json",
        params:
          address: val
          sensor: false
      ).then (response) ->
        return response.data.results.map (item)->
          return item.formatted_address
        

