(function() {
  var Shop, ShopSchema, mongoose;
  mongoose = require('mongoose');
  ShopSchema = new mongoose.Schema({
    shopUrl: String,
    shopifyPassword: String,
    posterousEmail: String,
    posterousPassword: String,
    posterousSiteId: String,
    postTitleTemplate: String,
    postBodyTemplate: String,
    postTags: String,
    aggregateImages: Boolean
  });
  exports.getSessionShop = function(req, res, next) {
    return Shop.findOne({
      shopUrl: req.session.shopUrl
    }, function(err, shop) {
      if (err != null) {
        throw err;
      }
      if (shop != null) {
        req.shop = shop;
        return next();
      } else {
        return next(new Error("Unrecognized shop identifier: " + req.session.shopUrl));
      }
    });
  };
  exports.Shop = Shop = mongoose.model('Shop', ShopSchema);
}).call(this);
