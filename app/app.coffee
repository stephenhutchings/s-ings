Application =
  initialize: ->
    window.iostap.initialize()
    hljs.initHighlightingOnLoad()

    for key, val of require("lib/easie")
      $.easing[key] = do (val) -> (t) -> val(t)


    $("html").removeClass("no-js")

    Router  = require("lib/router")
    @router = new Router()

    Backbone.history.start(pushState: true)

module.exports = Application
