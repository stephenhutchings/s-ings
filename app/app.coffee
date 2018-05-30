Application =
  initialize: ->
    # Set up the iostap listener
    window.iostap.initialize()

    # If there is code on the page, syntax highlight
    # This should be moved to the static compilation
    hljs.initHighlightingOnLoad()

    # Add all the easie methods to the jquery library
    for key, val of require("lib/easie")
      $.easing[key] = do (val) -> (t) -> val(t)

    # Certainly seems like JS is enabled
    $("html").removeClass("no-js")

    # Start the Backbone router
    Router  = require("lib/router")
    @router = new Router()
    Backbone.history.start(pushState: true)

module.exports = Application
