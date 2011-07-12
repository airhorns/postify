(function() {
  var POSTEROUS_API_KEY, Posterous, Postify, SHOPIFY_API_KEY, SHOPIFY_SHARED_SECRET, Shopify, app, express, handleError, mongoose, port;
  express = require('express');
  mongoose = require('mongoose');
  Postify = require('./lib/postify');
  Posterous = require('./lib/posterous');
  app = express.createServer();
  SHOPIFY_API_KEY = "dcc1dbfa9c731859eed2e8dcd1b84fa1";
  SHOPIFY_SHARED_SECRET = "5f78f1db3f8b32dbe13ff17ca4033be3";
  POSTEROUS_API_KEY = "DtkrGejBgnbJapqgoxGCbkscAvswrCIy";
  Shopify = (require('node-shopify'))(SHOPIFY_API_KEY, SHOPIFY_SHARED_SECRET);
  app.configure(function() {
    app.set('views', __dirname + '/views');
    app.set('view engine', 'jade');
    app.use(express.bodyParser());
    app.use(express.methodOverride());
    app.use(express.cookieParser());
    app.use(express.session({
      secret: SHOPIFY_API_KEY + POSTEROUS_API_KEY
    }));
    app.use(app.router);
    return app.use(express.static(__dirname + '/public'));
  });
  app.configure('development', function() {
    app.use(express.errorHandler({
      dumpExceptions: true,
      showStack: true
    }));
    return mongoose.connect('mongodb://localhost/postify_dev');
  });
  app.configure('production', function() {
    app.use(express.errorHandler());
    return mongoose.connect(process.env.MONGOHQ_URL);
  });
  handleError = function(error, res) {
    if (error.response) {
      return res.send(error, error.response.statusCode);
    } else {
      return res.send(error, 500);
    }
  };
  app.get('/', function(req, res) {
    return res.render('index', {
      title: 'Postify'
    });
  });
  app.get('/welcome', Shopify.ApiClient.verifySignatureFromRequest, function(req, res) {
    var go;
    go = function(shop, view) {
      return res.render(view, {
        title: 'Welcome to Postify',
        shop: shop
      });
    };
    return req.session.regenerate(function(err) {
      if (err != null) {
        throw err;
      }
      return Postify.Shop.findOne({
        shopUrl: req.param('shop')
      }, function(err, doc) {
        var shop;
        if (err != null) {
          throw err;
        }
        if (doc != null) {
          return go(doc, 'prefs');
        } else {
          shop = new Postify.Shop({
            shopUrl: req.param('shop'),
            shopifyPassword: Shopify.ApiClient.setPasswordFromParams(req.query)
          });
          return shop.save(function(err) {
            var shopResource;
            if (err != null) {
              throw err;
            }
            req.session.shopUrl = shop.shopUrl;
            shopResource = new Shopify.Shop({
              url: req.param('shop')
            });
            return go(shop, 'wizard');
          });
        }
      });
    });
  });
  app.post('/verify/posterous', Postify.getSessionShop, function(req, res) {
    var client;
    client = new Posterous(POSTEROUS_API_KEY, req.param('username'), req.param('password'));
    return client.getSites().on('success', function(sites) {
      return res.send(sites);
    }).on('error', function(error) {
      return handleError(error, res);
    });
  });
  app.post('/prefs', Postify.getSessionShop, function(req, res) {
    var shop;
    shop = req.shop;
    shop.posterousEmail = req.param('email');
    shop.posterousPassword = req.param('password');
    shop.posterousSiteId = req.param('posterous_site_id');
    shop.postTitleTemplate = req.param('post_title_template');
    shop.postBodyTemplate = req.param('post_body_template');
    shop.postTags = req.param('post_tags');
    shop.aggregateImages = req.param('aggregate_images');
    return shop.save(function(err) {
      if (err != null) {
        throw err;
      }
      return res.render('prefs', {
        title: "Success!",
        flashSuccess: {
          title: "Success!",
          body: "Postify has been set up correctly, and will publish all product updates from now on."
        },
        shop: shop
      });
    });
  });
  app.post('/post', Shopify.ApiClient.verifyWebhookFromRequest, function(req, res) {
    return res.send({
      x: "y"
    });
  });
  port = process.env.PORT || 3000;
  app.listen(port, function() {
    return console.log("Express server listening on port %d in %s mode", app.address().port, app.settings.env);
  });
}).call(this);
