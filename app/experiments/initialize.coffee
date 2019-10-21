# Required here to ensure inclusion in page-specific views
require("experiments/badge")
require("experiments/big-canvas")
require("experiments/color")
require("experiments/frame")
require("experiments/layer")
require("experiments/posterize")
require("experiments/resample")
require("experiments/sequence")
require("experiments/shape")
require("experiments/smooth")
require("experiments/threshold-to-mask")
require("experiments/wobble")
require("experiments/pos-or-neg")

require("experiments/line/dijkstra")
require("experiments/line/helpers")
require("experiments/line/levels")
require("experiments/line/shortest-path")

module.exports = (experiment) ->
  window.iostap.initialize()

  canvas  = null
  options = {}

  if window.location.search
    for opt in window.location.search.slice(1).split("&")
      [key, val] = opt.split("=")
      options[key] = (try JSON.parse(val)) or val

  draw = ->
    require("experiments/#{experiment}").draw options, (c) ->
      window.open(c.toDataURL(), "__blank") if c? and options.save
      canvas?.remove()

      document.body.classList.remove("show")

  ready = ->
    _.delay draw, 300
    # document.body.classList.add("show")

  if false
    fontName = "sans"
    fontPath = "url(/fonts/philippa/Philippa-Bold.woff)"
    new FontFace(fontName, fontPath).load().then(ready).catch(ready)
  else
    ready()

  $(".repeat").on "iostap", (e) ->
    canvas = document.querySelector("canvas")
    ready()
