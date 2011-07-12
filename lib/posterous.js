(function() {
  var Posterous, extend, querystring, restler;
  var __slice = Array.prototype.slice;
  querystring = require('querystring');
  restler = require('restler');
  extend = function() {
    var k, object, objects, onto, v, _i, _len;
    onto = arguments[0], objects = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
    for (_i = 0, _len = objects.length; _i < _len; _i++) {
      object = objects[_i];
      for (k in object) {
        v = object[k];
        onto[k] = v;
      }
    }
    return onto;
  };
  Posterous = restler.service(function(apiToken, username, password) {
    extend(this.defaults, {
      username: username,
      password: password
    });
    this.defaults.api_token = apiToken;
  }, {
    baseURL: 'http://posterous.com/api/2/'
  }, {
    getSites: function() {
      return this.get('sites', {
        query: {
          api_token: this.defaults.api_token
        }
      });
    },
    postToSite: function(siteId, post) {
      return this.post("sites/" + siteId + "/posts.json", {
        data: {
          post: post,
          api_token: this.defaults.api_token
        }
      });
    }
  });
  module.exports = Posterous;
}).call(this);
