# coffeelint: disable:max_line_length

bigCanvas = require("experiments/big-canvas")
sequence  = require("experiments/sequence")
helpers   = require("experiments/line/helpers")
posterize = require("experiments/posterize")
shortest  = require("experiments/line/shortest-path")

points = []

options =
  width: 600
  height: 600
  scale: 3
  radius: 3
  debug: true

dpi   = window.webkitDevicePixelRatio or window.devicePixelRatio or 1

p = ([x, y]) -> {x, y}

pos = (e) ->
  offset = e.currentTarget.getBoundingClientRect()
  x = (e.clientX - offset.left) * options.scale
  y = (e.clientY - offset.top) * options.scale
  [x, y]

e = (t) ->
  if (t *= 2) < 1
    return .5 * Math.pow(t, 5)
  else
    return .5 * ((t -= 2) * Math.pow(t, 4) + 2)


c =
  for n in [0..1]
    t = e(n / 1)
    k = Math.round(t * 255)
    [k,k,k]

draw = (overrides, done) ->
  _.extend options, overrides

  { canvas, ctx } = bigCanvas(options)

  canvas.width  *= options.scale
  canvas.height *= options.scale

  cx = (canvas.width) / 2
  cy = (canvas.height) / 2

  $("input").on("input", render)

  _.extend options, { cx, cy, ctx, canvas }

  sequence [
    render
    done
  ]

render = (debug) ->
  r  = options.radius * options.scale

  dv1 = parseFloat document.getElementById("d1").value
  dv2 = parseFloat document.getElementById("d2").value
  dv3 = parseFloat document.getElementById("d3").value

  v1  = parseFloat document.getElementById("v1").value
  v2  = parseFloat document.getElementById("v2").value
  v3  = parseFloat document.getElementById("v3").value

  p1  = parseFloat document.getElementById("p1").value
  p2  = parseFloat document.getElementById("p2").value
  p3  = parseFloat document.getElementById("p3").value
  p4  = parseFloat document.getElementById("p4").value

  console.log v1, v2, v3, p1, p2, p3

  p1 += v1
  p2 += v2
  p3 += v3

  fade = p4 / 4

  friction = document.getElementById("friction").value

  { canvas, ctx, cx, cy } = options

  ctx.fillStyle = "white"
  ctx.strokeStyle = "black"
  ctx.rect(0, 0, cx * 2, cy * 2)
  ctx.fill()

  ctx.lineWidth = options.scale

  now = Date.now()

  ctx.fillStyle = "rgba(0,0,0,0.1)"

  offsets = []

  for i in [0...p4]
    Δt = i

    t1 = (Δt % p1) / p1
    t2 = (Δt % p2) / p2
    t3 = (Δt % p3) / p3
    t4 = Δt / p4

    drag = 1 - t4 * friction

    d1 = dv1 * drag
    d2 = dv2 * drag
    d3 = dv3 * drag

    # 1 is circular
    x1 = Math.cos(Math.PI * 2 * t1) * d1
    y1 = Math.sin(Math.PI * 2 * t1) * d1

    # 2 is up/down
    x2 = Math.cos(Math.PI * 2 * t2) * d2
    y2 = Math.sin(Math.PI * 2 * t2) * d2

    # 3 is left/right
    x3 = Math.cos(Math.PI * 2 * t3) * d3
    y3 = Math.sin(Math.PI * 2 * t3) * d3

    offsets.push [cx + x1 + x2 + x3, cy + y1 + y2 + y3]

  offsets = helpers.arrayify(
    helpers.spline(
      helpers.objectify(offsets)
      # helpers.simplify(
      #   helpers.objectify(offsets)
      #   options.scale * 10
      # )
    )
  )




  fadeIn  = offsets.slice(0, fade)
  fadeOut = offsets.slice(-fade)
  theRest = offsets.slice(fade - 1, -fade + 1)

  for [x, y], i in fadeIn.slice(1)
    if i % 10 is 0
      ctx.globalAlpha = i / fadeIn.length
      ctx.beginPath()

    ctx.moveTo(fadeIn[i]...)
    ctx.lineTo(x, y)

    if i % 10 is 9
      ctx.stroke()

  ctx.stroke()

  f  = 40
  nb = ~~(theRest.length / f)

  for j in [0...f]
    n = ~~(nb * j)
    ctx.globalAlpha = 0.2 + 0.8 * Math.abs Math.cos(Math.PI * j / f)
    ctx.beginPath()
    ctx.moveTo(theRest[n]...)

    for [x, y] in theRest.slice(n + 1, n + nb + 1)
      ctx.lineTo(x, y)
      # ctx.translate(cx, cy)
      # ctx.rotate(t1 * Math.PI * 2)
      # ctx.translate(-cx, -cy)

    ctx.stroke()

  for [x, y], i in fadeOut.slice(1)
    if i % 10 is 0
      ctx.globalAlpha = 1 - i / fadeOut.length
      ctx.beginPath()

    ctx.moveTo(fadeOut[i]...)
    ctx.lineTo(x, y)

    if i % 10 is 9
      ctx.stroke()

  ctx.stroke()
  ctx.globalAlpha = 1


module.exports = { draw }
