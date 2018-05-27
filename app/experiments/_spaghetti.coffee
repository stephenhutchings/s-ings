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
    { canvas, ctx } = bigCanvas(options)

    scale = 1 #options.scale or 1

    canvas.width  *= scale
    canvas.height *= scale
    ctx.lineWidth = 2

    data =
      grid: 500
      radius: 60
      spin: 1
      color: 1 # between 0 and 1
      nib: 1
      strokeWidth: 8
      borderWidth: 1
      colors:
        fg: "rgba(255,255,255,0.1)"
        bg: "black"
        grid: "red"
        line: "red"
        border: "rgba(0,0,0,0.7)"
        number: "green"
        intersection: "cyan"

    sequence [
      =>
        ctx.fillStyle = data.colors.bg
        ctx.rect(0, 0, canvas.width, canvas.height)
        ctx.fill()
      => layer ctx, @grid(canvas, data)
      => data.line = @makeLine(canvas, data)
      =>
        return
        layer ctx, @line(canvas, data)
        layer ctx, @spiro(canvas, data)
      =>
        # return
        layer ctx, @line(canvas, data)
        data.spline = helpers.spline data.line
        data.spline = helpers.interpolate data.spline
        layer ctx, @line(canvas, data, true)
        layer ctx, @splino(canvas, data)

      => layer ctx, @number(canvas, data)
      =>
        # return
        zones = data.curve
        console.log zones
        intersections = _.chain(
          for zone in zones when zone.length > 0
            zone = _.compact(zone)
            for p0, i in zone
              p1 = zone[i + 1]
              i++
              for p2, j in zone when Math.abs(j - i) > 2
                p3 = zone[j + 1]
                j++
                if p0 and p1 and p2 and p3
                  helpers.intersection(
                    p0.x, p0.y
                    p1.x, p1.y
                    p2.x, p2.y
                    p3.x, p3.y
                  )
        )
          .flatten()
          .compact()
          .uniq()
          .value()

        console.log intersections
        # return

        ctx.strokeStyle = data.colors.intersection
        ctx.beginPath()
        for {x, y} in intersections
          ctx.moveTo(x + 8, y)
          ctx.arc(x, y, 8, 0, Math.PI * 2)
        ctx.stroke()


      # -> resample(ctx, canvas, 0.5)
      # -> posterize(canvas, 5, [[0,0,0], [255,255,255]])
      # -> resample(ctx, canvas, 2)
      # -> resample(ctx, canvas, scale)
      -> done canvas
    ]

  grid: ({ width, height }, data) ->
    canvas = document.createElement("canvas")
    ctx    = canvas.getContext("2d")

    canvas.width  = width
    canvas.height = height
    ctx.fillStyle = data.colors.grid

    for { x, y } in helpers.makeGrid(width, height, data.grid)
      ctx.beginPath()
      ctx.arc(x, y, 1, 0, Math.PI * 2)
      ctx.closePath()
      ctx.fill()

    ctx.getImageData(0, 0, canvas.width, canvas.height)

  makeLine: ({ width, height }, data) ->
    points  = helpers.makeGrid(width, height, data.grid)
    current = _.sample(points)
    line    = [current]
    limit   = 99

    gw      = Math.floor(width / data.grid) + 1
    gh      = Math.floor(height / data.grid) + 1

    while points.length * data.color > _.uniq(line).length and limit > 0
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

  line: ({ width, height }, data, useSpline) ->
    canvas = document.createElement("canvas")
    ctx    = canvas.getContext("2d")

    canvas.width    = width
    canvas.height   = height
    ctx.strokeStyle = data.colors.line

    ctx.beginPath()

    for { x, y, moveTo }, i in (if useSpline then data.spline else data.line)
      fn = if i is 0 or moveTo then "moveTo" else "lineTo"
      ctx[fn](x, y)

    ctx.stroke()
    ctx.getImageData(0, 0, canvas.width, canvas.height)

  splino: ({ width, height }, data) ->
    canvas = document.createElement("canvas")
    ctx    = canvas.getContext("2d")

    canvas.width = width
    canvas.height = height

    ctx.fillStyle = data.colors.fg

    dist = 500
    offset = 0
    radius = data.radius
    radiusOffset = 0

    do newValues = ->
      # dist   = _.sample([300,400,500,600])
      radiusOffset = wobble(10) * 10


    zonalDivisions = 30

    gw = Math.floor(width / zonalDivisions)
    gh = Math.floor(height / zonalDivisions)
    data.curve = ([] for i in [0...(gw * gh)])

    for p0, i in data.spline.slice(0, -1)
      p1 = data.spline[i + 1]
      dx = p1.x - p0.x
      dy = p1.y - p0.y

      t = (dist / 2 - i % dist) / (dist / 2)

      # console.log radius
      # dist   = _.random(500, 60)

      nx = p0.x + dx * t
      ny = p0.y + dy * t
      theta = (t * Math.PI * 2)

      r = (radius + radiusOffset * (i % dist) / dist)

      if i % dist is 0
        newValues()

      x = nx + Math.cos(theta) * r
      y = ny + Math.sin(theta) * r

      if x > 0 and y > 0 and x < width and y < height
        ctx.beginPath()
        ctx.arc(x, y, data.strokeWidth, 0, Math.PI * 2)
        ctx.fill()

        # zone = x
        zone = Math.floor(x / zonalDivisions) + Math.floor(y / zonalDivisions) * gw
        data.curve[zone]?[i] = {x, y}

    ctx.getImageData(0, 0, canvas.width, canvas.height)

  spiro: ({ width, height }, data) ->
    canvas = document.createElement("canvas")
    ctx    = canvas.getContext("2d")

    canvas.width = width
    canvas.height = height

    ctx.fillStyle = data.colors.fg

    for p0, i in data.line.slice(0, -1)
      p1 = data.line[i + 1]
      dx = p1.x - p0.x
      dy = p1.y - p0.y
      dist = Math.sqrt((dx * dx) + (dy * dy))
      k = dist

      radius = wobble(data.radius, 1)

      pt = Math.atan2(p1.y - p0.y, p1.x - p0.x)
      # pt = 0

      for d in [0..k]
        t = d / k
        dx = p0.x + (p1.x - p0.x) * t
        dy = p0.y + (p1.y - p0.y) * t

        sinEasing = .8 * Math.sin(t * Math.PI) + .2
        theta = (t * Math.PI * 2) * data.spin
        x = dx + Math.cos(theta) * (radius * sinEasing)
        y = dy + Math.sin(theta) * (radius * sinEasing)

        ctx.beginPath()

        arcRadius =
          if data.nib
            data.strokeWidth * sinEasing
          else
            data.strokeWidth

        ctx.arc(x, y, arcRadius, 0, Math.PI * 2)
        ctx.fill()


        if data.borderWidth
          ctx.beginPath()
          ctx.fillStyle = data.colors.border

          # Outer
          x = dx + Math.cos(theta) * (radius * sinEasing + arcRadius)
          y = dy + Math.sin(theta) * (radius * sinEasing + arcRadius)
          ctx.arc(x, y, data.borderWidth * sinEasing, 0, Math.PI * 2)
          ctx.fill()

          ctx.beginPath()
          # ctx.fillStyle = "red"

          # Inner
          x = dx + Math.cos(theta) * (radius * sinEasing - arcRadius)
          y = dy + Math.sin(theta) * (radius * sinEasing - arcRadius)
          ctx.moveTo(x, y)
          ctx.arc(x, y, data.borderWidth * sinEasing, 0, Math.PI * 2)

          ctx.fill()
          ctx.fillStyle = data.colors.fg

    ctx.getImageData(0, 0, canvas.width, canvas.height)

  number: ({ width, height }, data) ->
    canvas = document.createElement("canvas")
    ctx    = canvas.getContext("2d")

    canvas.width = width
    canvas.height = height

    ctx.font      = "700 20px sans"
    ctx.fillStyle = data.colors.number
    ctx.beginPath()

    for { x, y }, i in data.line
      ctx.fillText(i, x, y)

    ctx.getImageData(0, 0, canvas.width, canvas.height)
