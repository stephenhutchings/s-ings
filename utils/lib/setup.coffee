jsdom = require "jsdom"
loggy = require "loggy"

virtualConsole = jsdom.createVirtualConsole().sendTo(loggy)
virtualConsole.on "jsdomError", (e) -> console.error(e.stack, e.detail)

module.exports = (done) ->
  t = setTimeout ->
    throw new Error("Timeout")
  , 8000

  jsdom.env
    html: ""
    scripts: [
      "./build/js/vendor.js"
      "./build/js/other/stack-blur.js"
      "./build/js/other/canvas-fx.js"
      "./build/js/experiments.js"
    ]

    done: (err, window) ->
      if err?
        throw err
      else
        clearTimeout t
        done(err, window)

    features:
      FetchExternalResources: ["img"]

    virtualConsole: virtualConsole
