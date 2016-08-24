module.exports = (experiment) ->
  $(document).ready ->
    window.iostap.initialize()

    label = document.querySelector("label")

    draw = ->
      label.removeEventListener("transitionend", draw)
      require("experiments/#{experiment}").draw ->
        label.classList.remove("show")

    ready = ->
      label.addEventListener("transitionend", draw)
      label.classList.add("show")

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
        document.querySelector("canvas")?.remove()
        ready()
