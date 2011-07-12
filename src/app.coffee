express   = require 'express'
mongoose  = require 'mongoose'
Postify   = require './lib/postify'
Posterous = require './lib/posterous'

app = express.createServer()
SHOPIFY_API_KEY       = "dcc1dbfa9c731859eed2e8dcd1b84fa1"
SHOPIFY_SHARED_SECRET = "5f78f1db3f8b32dbe13ff17ca4033be3"
POSTEROUS_API_KEY     = "DtkrGejBgnbJapqgoxGCbkscAvswrCIy"

Shopify   = (require 'node-shopify')(SHOPIFY_API_KEY, SHOPIFY_SHARED_SECRET)

# Configuration of Express web server
app.configure ->
  app.set 'views', __dirname + '/views'
  app.set 'view engine', 'jade'
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use express.cookieParser()
  app.use express.session({ secret: SHOPIFY_API_KEY + POSTEROUS_API_KEY })
  app.use app.router
  app.use express.static(__dirname + '/public')

app.configure 'development', () ->
  app.use express.errorHandler(dumpExceptions: true, showStack: true)
  mongoose.connect('mongodb://localhost/postify_dev')

app.configure 'production', () ->
  app.use express.errorHandler()
  mongoose.connect(process.env.MONGOHQ_URL)

handleError = (error, res) ->
  if error.response
    res.send error, error.response.statusCode
  else
    res.send error, 500

# Routes
app.get '/', (req, res) ->
  res.render 'index',
    title: 'Postify'

# Users are redirected here when they first install the app, or when they log in any
# any time after. We stick in a route middleware which verifies the signature passed 
# from Shopify using the shared secret known to only this app and the Shopify servers,
# ensuring the request is in fact 'coming' from Shopify.
app.get '/welcome', Shopify.ApiClient.verifySignatureFromRequest, (req, res) ->
  # What will eventually be done, called in the callbacks below.
  go = (shop, view) ->
    res.render view,
      title: 'Welcome to Postify'
      shop: shop

  # Regenerate the session every time this URL is hit to ensure that if the same user uses two shops
  # and two Postifys, the lines between them aren't blurred.
  req.session.regenerate (err) ->
    throw err if err?
    
    # See if the shop already exists (because the user visited before). If so, we can just show the 
    # preferences form to the user and send them on their way. Otherwise, we need to create our 
    # internal objects, persist them, and leave some indicators in the session for the next requests.
    Postify.Shop.findOne {shopUrl: req.param('shop')}, (err, doc) -> 
      throw err if err?

      # If the mongo record exists already, just spit it out to the user in the prefs view.
      if doc?
        go(doc, 'prefs')
      else
        # If not, create a new Mongo record which stores the shop URL and the password calculated from the 
        # query params. This password is what we use to authenticate in future Shopify API requests.
        shop = new Postify.Shop
          shopUrl: req.param('shop')
          shopifyPassword: Shopify.ApiClient.setPasswordFromParams(req.query) # Get the password from the `ApiClient`.
        
        shop.save (err) ->
          throw err if err?

          # Store the `shopUrl` in the session, never to be editable by users again.
          # This way, they can only modify the values of their own shop.
          req.session.shopUrl = shop.shopUrl

          # Also, create the webhook which powers Postify for the user, since this
          # is the first time they are visiting and we know they don't have it yet.
          shopResource = new Shopify.Shop(url: req.param('shop'))
          #hook = shopResource.buildWebhook(topic: "products/create", format: "json", address: "http://postify.heroku.com/post")

          # Save the webhook resource to the Shopify API. Once thats done, render the view to the user.
          #hook.afterSave ->
          go(shop, 'wizard')

          #hook.save()

# This route is called via ajax to fetch the list of sites which the user has with Posterous.
app.post '/verify/posterous', Postify.getSessionShop, (req, res) ->
  # Instantiate a new Posterous api client as defined in src/posterous.coffee.
  client = new Posterous(POSTEROUS_API_KEY, req.param('username'), req.param('password'))

  # Hit the Posterous API for a list of the sites a user owns, which the client will then work with.
  client.getSites().on('success', (sites) ->
    res.send sites
  ).on('error', (error) -> 
    handleError(error, res)
  )

# All the stuff filled out in either the wizard or the normal prefs form is submitted here.
app.post '/prefs', Postify.getSessionShop, (req, res) ->
  shop = req.shop
  shop.posterousEmail = req.param('email')
  shop.posterousPassword = req.param('password')
  shop.posterousSiteId = req.param('posterous_site_id')
  shop.postTitleTemplate = req.param('post_title_template')
  shop.postBodyTemplate = req.param('post_body_template')
  shop.postTags = req.param('post_tags')
  shop.aggregateImages = req.param('aggregate_images')
  shop.save (err) ->
    throw err if err?
    res.render 'prefs'
      title: "Success!"
      flashSuccess: 
        title: "Success!"
        body: "Postify has been set up correctly, and will publish all product updates from now on."
      shop: shop

# Called by the Shopfiy webhook to actually accomplish anything.
app.post '/post', Shopify.ApiClient.verifyWebhookFromRequest, (req, res) ->
  res.send {x: "y"}

port = process.env.PORT || 3000
app.listen port, ->
  console.log("Express server listening on port %d in %s mode", app.address().port, app.settings.env)
