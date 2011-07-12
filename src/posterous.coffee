querystring = require 'querystring'
restler = require 'restler'

extend = (onto, objects...) ->
  for object in objects
    for k, v of object
      onto[k] = v
  onto

Posterous = restler.service((apiToken, username, password) ->
  extend @defaults, {username, password}
  @defaults.api_token = apiToken
  return
, {
  baseURL: 'http://posterous.com/api/2/'
}, {
  getSites: -> @get('sites', {query: {api_token: @defaults.api_token}})
  postToSite: (siteId, post) -> @post("sites/#{siteId}/posts.json", {data: {post, api_token: @defaults.api_token}})
})

module.exports = Posterous
