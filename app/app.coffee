Application =
  initialize: ->
    window.iostap.initialize()
    hljs.initHighlightingOnLoad()

    $("html").removeClass("no-js")

    Router  = require("lib/router")
    @router = new Router()

    Backbone.history.start(pushState: true)


module.exports = Application
