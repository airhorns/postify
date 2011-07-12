mongoose = require 'mongoose'

ShopSchema = new mongoose.Schema
  shopUrl: String
  shopifyPassword: String
  posterousEmail: String
  posterousPassword: String
  posterousSiteId: String
  postTitleTemplate: String
  postBodyTemplate: String
  postTags: String
  aggregateImages: Boolean

exports.getSessionShop = (req, res, next) ->
  Shop.findOne {shopUrl: req.session.shopUrl}, (err, shop) -> 
    throw err if err?
    # If so, just spit it out to the user
    if shop?
      req.shop = shop
      next()
    else
      next(new Error("Unrecognized shop identifier: #{req.session.shopUrl}"))


exports.Shop = Shop = mongoose.model 'Shop', ShopSchema
