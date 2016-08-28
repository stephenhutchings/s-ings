module.exports = (experiment) ->
  window.iostap.initialize()

  canvas  = null
  label   = document.querySelector("label")
  options = {}

  if window.location.search
    for opt in window.location.search.slice(1).split("&")
      [key, val] = opt.split("=")
      options[key] = (try JSON.parse(val)) or val

  console.log options
  draw = ->
    require("experiments/#{experiment}").draw options, (c) ->
      window.open(c.toDataURL(), "__blank") if c? and options.save
      canvas?.remove()

      document.body.classList.remove("show")

  ready = ->
    _.delay draw, 300
    document.body.classList.add("show")

  if window.FontFace
    fontName = "Texta"
    fontPath = "url(/fonts/texta-black/texta-black-webfont.woff2)"
    new FontFace(fontName, fontPath).load().then(ready)
  else
    ready()

  $(document).on "iostap", (e) ->
    if e.target.href
      window.location = e.target.href
    else
      canvas = document.querySelector("canvas")
      ready()
