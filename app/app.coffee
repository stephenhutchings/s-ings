NiceTouch = require("lib/touch")

Application =
  initialize: ->
    NiceTouch.initialize()
    hljs.initHighlightingOnLoad()

    $("html").removeClass("no-js")

    Router  = require("lib/router")
    @router = new Router()

    Backbone.history.start(pushState: true)

module.exports = Application
