easie     = require("lib/easie")
bigCanvas = require("experiments/big-canvas")
sequence  = require("experiments/sequence")
layer     = require("experiments/layer")
wobble    = require("experiments/wobble")
posterize = require("experiments/posterize")
resample  = require("experiments/resample")
helpers   = require("experiments/line/helpers")


# All the points in the grid of width with distance of the index point
subGrid = (grid, index, width, height, limit) ->
  px = (index % width)
  py = Math.floor(index / width)

  _.chain(
    for row in [-limit..limit]
      for col in [-limit..limit]
        x = px + col
        y = py + row
        if 0 <= x < width and
           0 <= y < height
          grid[Math.min(y * width + x, grid.length - 1)]
  )
    .flatten()
    .compact()
    .value()


module.exports =
  draw: (options, done) ->
    { canvas, ctx } = bigCanvas({width: 3200, height: 2400, padding: 40})

    data =
      scale: 1.5
      inset: 600
      radius:
        min: 12
        max: 320
      kink: 400
      frequency: 900
      gridSize: 100
      gridWobble: 150
      borderWidth: 16
      segmentWidth: 8
      shadowWidth: 20
      strokeWidth:
        min: 20
        max: 20
      colors:
        fg: "rgba(255,255,255,1)"
        bg: "#282b2f"
        fade: "rgba(255,255,255, .02)"
        grid: "red"
        line: "black"
        border: "rgba(0,0,0,0.7)"
        number: "#666"
        intersection: "cyan"
        shadow: "#ccc"

    canvas.width  *= data.scale
    canvas.height *= data.scale
    ctx.lineWidth = 2

    data.matrix = helpers.makeGrid(
      canvas.width  - data.inset * 2
      canvas.height - data.inset * 2
      data.gridSize
    ).map (point) ->
      x: data.inset + wobble(point.x, data.gridWobble)
      y: data.inset + wobble(point.y, data.gridWobble)

    sequence [
      => data.line = @makeLine(canvas, data)
      # => layer ctx, @wrap @number, canvas, data
      # => layer ctx, @wrap @line, canvas, data
      =>
        divisions = 800
        [p1, p2, rest..., p3, p4] = data.line
        data.spline = helpers.spline([p3, p4, data.line..., p1, p2], divisions)
        data.spline = data.spline.slice(1, divisions * data.line.length + 3)
      # => layer ctx, @wrap @grid, canvas, data
      # => data.spline = helpers.interpolate data.spline
      => layer ctx, @wrap @line, canvas, data, true
      # -> ctx.clearRect(0, 0, canvas.width, canvas.height)
      => @spirograph canvas, ctx, data
      # => layer ctx, @wrap @intersections, canvas, data
      # -> posterize(canvas, 8, "grayscale")
      # -> resample(ctx, canvas, data.scale)
      -> done canvas
    ]

  grid: ({ width, height }, ctx, data) ->
    ctx.fillStyle = data.colors.grid
    ctx.beginPath()

    for { x, y } in data.matrix
      ctx.moveTo(x + 2, y)
      ctx.arc(x, y, 2, 0, Math.PI * 2)

    ctx.fill()

  makeLine: ({ width, height }, data) ->
    points  = data.matrix
    current = _.sample(points)
    line    = [current]
    limit   = 99

    gw      = Math.floor((width -  data.inset * 2) / data.gridSize) + 1
    gh      = Math.floor((height - data.inset * 2) / data.gridSize) + 1

    while points.length > _.uniq(line).length and limit > 0
      index   = points.indexOf(current)
      next    = null

      for d in [3..16]
        sub = subGrid(points, index, gw, gh, d)
        fsub = _.without(sub, line...)
        if fsub.length
          next = _.sample(fsub)
          break
        else if d > 8
          limit--

      next ?= _.sample(sub)

      if next
        current = next
        line.push(current)

    return line

  line: ({ width, height }, ctx, data, useSpline) ->
    ctx.strokeStyle = data.colors.line
    ctx.beginPath()
    ctx.lineWidth = 1.5

    for { x, y, moveTo }, i in (if useSpline then data.spline else data.line)
      fn = if i is 0 or moveTo then "moveTo" else "lineTo"
      ctx[fn](x, y)

    ctx.stroke()

  spirograph: ({ width, height }, ctx, data) ->
    ctx.fillStyle = data.colors.fg

    freq   = data.frequency

    data.curve = []

    r1 = r2 = 0

    radii =
      _.flatten(
        for n in [0..data.kink]
          r1 = r2 or _.random(data.radius.min, data.radius.max)
          r2 =       _.random(data.radius.min, data.radius.max)
          len = (data.spline.length / data.kink)

          for j in [0..(len - 1)]
            t = easie.cubicInOut(j / len, 0, 1, 1)
            r1 + (r2 - r1) * t
      )

    # sequence steps =
    for p0, i in data.spline.slice(0, -1)

      p1 = data.spline[i + 1]
      dx = p1.x - p0.x
      dy = p1.y - p0.y

      rx = radii[Math.min(i, radii.length)]


      t = (freq / 2 - i % freq) / (freq / 2)

      px = p0.x + dx * t
      py = p0.y + dy * t
      theta = (t * Math.PI * 2)

      rd = (data.strokeWidth.max - data.strokeWidth.min)
      r = data.strokeWidth.min + rd * Math.abs(t)
      r = Math.max(r, 2)

      x = px + Math.cos(theta) * rx
      y = py + Math.sin(theta) * rx

      # Blend the last points back to the first
      k  = data.spline.length / data.kink
      n  = data.spline.length
      # if i > n - k
      #   fn = i % (n - k) / k
      #   # x0 = data.curve[0].x
      #   # y0 = data.curve[0].y
      #   r0 = data.curve[0].r
      #   t0 = data.curve[0].theta
      #   rx0 = data.curve[0].rx

      #   r += (r0 - r) * fn
      #   # rx += (rx0 - rx) * fn * -1
      #   theta += (Math.PI * 2 - theta) * fn
      #   x = px + Math.cos(theta) * rx
      #   y = py + Math.sin(theta) * rx


      data.curve.push { x, y, r, rx, theta }

          # if x > 0 and y > 0 and x < width and y < height
          #   drawWithBorder(data, ctx)

    curve = data.curve
    batch = 5000
    console.log curve
    steps = (
      for j in [0..curve.length / batch]
        do (j) => =>
          new Promise ((res) =>
            layer ctx, @wrap((canvas, lc, d, j) ->
              for i in [0..batch]
                ii = j * batch
                data.curve = curve.slice(ii, ii + i + 1)
                drawWithBorder(data, lc)
                res() if i is batch - 1
            , {width, height}, data, j)
          )

    )

    sequence steps
    # ctx.beginPath()
    # ctx.globalCompositeOperation = "source-over"
    # for {x,y}, i in data.curve
    #   ctx[if i is 0 then "moveTo" else "lineTo"](x, y)
    # ctx.stroke()

  number: ({ width, height }, ctx, data) ->
    ctx.font      = "700 20px sans"
    ctx.fillStyle = data.colors.number
    ctx.beginPath()

    for { x, y }, i in data.line
      ctx.fillText(i, x, y)

  wrap: (method, { width, height }, data, args...) ->
    canvas        = document.createElement("canvas")
    ctx           = canvas.getContext("2d")
    canvas.width  = width
    canvas.height = height

    method(canvas, ctx, data, args...)
    ctx.getImageData(0, 0, canvas.width, canvas.height)

isUnder    = false
shouldFlip = false
alphaCount = 0

checkUnderness = (x, y, r, t, ctx) ->
  alpha  = 0
  debug  = 0
  points = []

  # For each point along the width of the next line, check for transparency
  for ri in [-r..r]
    break if alpha > 0

    qx = Math.round x + Math.cos(t) * 1 + Math.cos(t - Math.PI / 2) * ri
    qy = Math.round y + Math.sin(t) * 1 + Math.sin(t - Math.PI / 2) * ri
    points.push(x: qx, y: qy)
    alpha = ctx.getImageData(qx, qy, 1, 1).data[3]

  if debug and points.length
    ctx.beginPath()
    ctx.moveTo(points[0].x, points[0].y)
    ctx.lineTo(_.last(points).x, _.last(points).y)
    ctx.stroke()

  if alpha isnt 0
    shouldFlip = true
    alphaCount = 1

  else if shouldFlip
    alphaCount--

    if alphaCount is 0
      isUnder = not isUnder
      shouldFlip = false

  return isUnder

drawWithBorder = (data, ctx) ->
  i = data.curve.length - 1
  return if i is 0
  { x, y, r, theta } = data.curve[i - 1]
  p0 = data.curve[i - 2]
  p1 = data.curve[i]

  # The angle between this point and the last
  t =
    if p1
      Math.atan2(p1.y - y, p1.x - x)
    else
      -Math.PI / 2

  t0 =
    if p0 and p1
      Math.atan2(y - p0.y, x - p0.x)
    else
      -Math.PI / 2

  # The distance between this point and the last
  dist =
    if p0 and p1
      Math.sqrt(Math.pow(p1.x - p0.x, 2) + Math.pow(p1.y - p0.y, 2))
    else
      0

  bw = Math.sin((i % 100 / 50) * Math.PI / 2) * data.borderWidth

  # if dist < 2
  #   # This is roughly between 40 and 160 degrees in one go,
  #   # so do up to 6 extra interpolations, not really working
  #   n = 1 + Math.round(15 * Math.abs(t) / (Math.PI))
  #   console.log n
  #   dx = x
  #   dy = y
  #   dt = t
  #   dr = r
  #   interpolations =
  #     for j in [0..n]
  #       d  = j / n
  #       r  = dr + d * (p1.r - dr)
  #       td = dt + n * (t0 - t)
  #       x  = dx + d * Math.cos(td) * dist
  #       y  = dy + d * Math.sin(td) * dist
  #       {x, y, t: td, r}
  #   console.log interpolations
  # else
  #   interpolations = [{x, y, t, r}]

  dist = Math.max(dist, data.segmentWidth)

  ctx.strokeStyle = if i % 3 is 0 then "rgba(0,0,0,0.1)" else "transparent"
  ctx.lineWidth = bw
  width = r + bw
  width += data.shadowWidth if isUnder
  isUnder = checkUnderness(p1.x, p1.y, width, t, ctx)

  # for {x,y,t,r} in interpolations
  # Back line points
  x1 = x + Math.cos(t + Math.PI / 2) *  (r + bw)
  y1 = y + Math.sin(t + Math.PI / 2) *  (r + bw)
  x2 = x + Math.cos(t + Math.PI / 2) * -(r + bw)
  y2 = y + Math.sin(t + Math.PI / 2) * -(r + bw)

  # Front line points
  x3 = x + Math.cos(t + Math.PI / 2) *  r
  y3 = y + Math.sin(t + Math.PI / 2) *  r
  x4 = x + Math.cos(t + Math.PI / 2) * -r
  y4 = y + Math.sin(t + Math.PI / 2) * -r

  if data.shadowWidth
    # Shadow point
    x5 = x + Math.cos(t + Math.PI / 2) *  (r + data.shadowWidth)
    y5 = y + Math.sin(t + Math.PI / 2) *  (r + data.shadowWidth)
    x6 = x + Math.cos(t + Math.PI / 2) * -(r + data.shadowWidth)
    y6 = y + Math.sin(t + Math.PI / 2) * -(r + data.shadowWidth)

    ctx.lineWidth   = dist

    # Draw a shadow element
    ctx.globalCompositeOperation = "source-atop"
    ctx.globalAlpha = 0.2
    ctx.strokeStyle = data.colors.bg

    if not isUnder
      ctx.beginPath()
      ctx.moveTo(x3, y3)
      ctx.lineTo(x5, y5)
      ctx.moveTo(x4, y4)
      ctx.lineTo(x6, y6)
      ctx.stroke()

  ctx.globalCompositeOperation =
    if isUnder then "destination-over" else "source-over"

  ctx.globalAlpha = 1

  if isUnder
    ctx.strokeStyle = data.colors.shadow
    ctx.beginPath()
    ctx.moveTo(x4, y4)
    ctx.lineTo( x,  y)
    ctx.stroke()

  # Draw the front line
  ctx.strokeStyle = data.colors.fg
  ctx.beginPath()
  ctx.moveTo(x3, y3)
  ctx.lineTo(x4, y4)
  ctx.stroke()

  # Draw the back line in two parts
  ctx.strokeStyle = data.colors.bg
  ctx.beginPath()
  ctx.moveTo(x1, y1)
  ctx.lineTo(x3, y3)
  ctx.moveTo(x4, y4)
  ctx.lineTo(x2, y2)
  ctx.stroke()

  if not isUnder
    ctx.strokeStyle = data.colors.shadow
    ctx.beginPath()
    ctx.moveTo(x4, y4)
    ctx.lineTo( x,  y)
    ctx.stroke()
