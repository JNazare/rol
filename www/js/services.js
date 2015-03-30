// Generated by CoffeeScript 1.9.1
(function() {
  var appServices;

  appServices = angular.module('app.services', []);

  appServices.factory('kinveyFactory', [
    "$kinvey", function($kinvey) {
      var promise;
      promise = $kinvey.init({
        appKey: "kid_bkOlUtsa2",
        appSecret: "3e534d0a09d6494d916a07c9e6afe54a",
        sync: {
          enable: true
        }
      });
      promise.then(function(kinveyUser) {
        return kinveyUser;
      });
      return promise;
    }
  ]);

}).call(this);
