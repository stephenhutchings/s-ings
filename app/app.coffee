NiceTouch = require("lib/touch")

Application =
  initialize: ->
    NiceTouch.initialize()
    hljs.initHighlightingOnLoad()

    Router  = require("lib/router")
    @router = new Router()

    Backbone.history.start(pushState: true)

module.exports = Application
