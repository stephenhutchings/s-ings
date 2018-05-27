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
    document.body.classList.add("show")

  if false
    fontName = "sans"
    fontPath = "url(/fonts/philippa/Philippa-Bold.woff)"
    new FontFace(fontName, fontPath).load().then(ready).catch(ready)
  else
    ready()

  $(".repeat").on "iostap", (e) ->
    canvas = document.querySelector("canvas")
    ready()
