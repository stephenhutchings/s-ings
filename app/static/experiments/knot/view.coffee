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

mousedown = false
didMove = false
active = null

p = ([x, y]) -> {x, y}

pos = (e) ->
  offset = e.currentTarget.getBoundingClientRect()
  x = (e.clientX - offset.left) * options.scale
  y = (e.clientY - offset.top) * options.scale
  [x, y]

onDown = (e) ->
  mousedown = true
  fuzz = 20

  [x, y] = pos(e)

  active = null
  for p1, i in points
    dist = Math.sqrt helpers.distance(p(p1), p([x, y]))
    if dist < options.scale * options.radius + fuzz
      active = i

  if not active?
    active = points.length
    didMove = true
    points.push [x, y]
    render()

onMove = (e) ->
  return unless mousedown

  didMove = true

  points[active] = pos(e)
  render(null, true)

onUp = (e) ->
  if active? and not didMove
    points.splice(active, 1)
    render()

  mousedown = false
  didMove = false

onOver = ->
  render(null, true)

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

console.log c

# c = [
#   [255,0,0]
#   [0,0,255]
# ]

onLeave = ->
  sequence [
    render
    -> posterize(options.canvas, .5 * options.scale, c)
  ]

draw = (overrides, done) ->
  _.extend options, overrides

  { canvas, ctx } = bigCanvas(options)

  $(canvas).on("mousedown", onDown)
  $(canvas).on("mousemove", onMove)
  $(canvas).on("mouseup", onUp)
  $(window).on("keydown", onOver)
  $(window).on("keyup", onLeave)
  $("input").on("input", render)

  canvas.width  *= options.scale
  canvas.height *= options.scale

  cx = (canvas.width) / 2
  cy = (canvas.height) / 2

  points = [
    # [cx, 10]
    # [cx + 96, 112]
    [cx + 60, cy]
    [cx - 60, cy / 3 * 2 - 12]
    [cx + 60, cy / 3]
    [cx - 48, cy / 3]
    [cx + 60, cy / 3 * 2]
  ]

  _.extend options, { cx, cy, ctx, canvas }

  sequence [
    render
    done
  ]

render = (done = (->), debug) ->
  options.sides  = document.getElementById("sides").value
  options.period = document.getElementById("period").value
  options.stroke = document.getElementById("stroke").value
  options.debug  = document.getElementById("debug").checked

  r  = options.radius * options.scale

  { canvas, ctx, cx, cy } = options

  ctx.fillStyle = "white"
  ctx.strokeStyle = "black"
  ctx.rect(0, 0, cx * 2, cy * 2)
  ctx.fill()

  window.ctx = ctx
  ctx.font = "#{12 * options.scale}px sans"
  ctx.lineWidth = options.stroke

  line = []

  for s in [0...options.sides]
    t = 1-Math.sin(Math.PI * 2 * (s / options.sides * options.period)) / options.period
    for [px, py] in points
      dx = (px - cx)
      dy = (py - cy)
      Ø = Math.atan2(dy, dx)
      d = Math.sqrt(Math.pow(dx, 2) + Math.pow(dy, 2)) * t
      x = cx + Math.cos(Ø + s * Math.PI * 2 / options.sides) * d
      y = cy + Math.sin(Ø + s * Math.PI * 2 / options.sides) * d

      line.push {x, y}

  spline = helpers.spline(line.concat(line[0...3])).slice(1)
  spline = helpers.simplify spline, 0.5, true

  xs = _.pluck(spline, "x")
  ys = _.pluck(spline, "y")
  minX = _.min(xs)
  maxX = _.max(xs)
  minY = _.min(ys)
  maxY = _.max(ys)
  w = maxX - minX
  h = maxY - minY

  ctx.save()

  if not(options.debug or debug)
    ctx.translate(
      -(minX + w / 2) + cx
      -(minY + h / 2) + cy
    )

  # ctx.strokeStyle = "rgba(0,0,0,0.6)"
  ctx.beginPath()
  ctx.moveTo(spline[0].x, spline[0].y)
  ctx.lineTo(x, y) for {x, y} in spline.slice(1)
  ctx.closePath()
  ctx.stroke()

  if options.debug or debug
    ctx.fillStyle = "rgba(0,0,0,0.1)"
    ctx.beginPath()
    for {x, y} in line.slice(points.length)
      ctx.moveTo(x + r, y)
      ctx.arc(x, y, r, 0, Math.PI * 2)

    ctx.fill()

    ctx.fillStyle = "red"
    ctx.beginPath()
    for [x,y] in points
      ctx.moveTo(x + r, y)
      ctx.arc(x, y, r, 0, Math.PI * 2)

    ctx.fill()

    for [x,y], i in points
      ctx.fillText(i, x + 12, y)

    ctx.fill()

  ctx.restore()

module.exports = { draw }
