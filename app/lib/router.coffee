MainView = require("views/main")

class AppRouter extends Backbone.Router

  initialize: ->
    @mainView = new MainView(el: "body")

  routes:
    "*default": "default"

  default: (route = "index") ->
    @mainView.display(route)

module.exports = AppRouter
