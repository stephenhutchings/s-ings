# coffeelint: disable:max_line_length

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
    { canvas, ctx } = bigCanvas(options)

    data =
      scale: 1 #options.scale or 1
      inset: 200
      radius:
        min: 12
        max: 180
      kink: 800
      frequency: 800
      gridSize: 50
      gridWobble: 50 * .33
      zoneSize: 30
      color: 1 # between 0 and 1
      nib: 1
      strokeWidth:
        min: 8
        max: 80
      borderWidth: 2
      colors:
        fg: "rgba(200,210,220,1)"
        bg: "#282b2f"
        fade: "rgba(255,255,255, .02)"
        grid: "red"
        line: "black"
        border: "rgba(0,0,0,0.7)"
        number: "#666"
        intersection: "cyan"

    canvas.width  *= data.scale
    canvas.height *= data.scale
    ctx.lineWidth = 2

    ctx.fillStyle = data.colors.bg
    ctx.rect(0, 0, canvas.width, canvas.height)
    ctx.fill()

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
        [p1, rest..., p3, p4] = data.line
        data.spline = helpers.spline([p3, p4, data.line..., p1]).slice(1,-1)
      => layer ctx, @wrap @grid, canvas, data
      => data.spline = helpers.interpolate data.spline
      => layer ctx, @wrap @line, canvas, data, true
      => @spirograph canvas, ctx, data
      # => layer ctx, @wrap @intersections, canvas, data
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
    zones  = data.zoneSize

    gw = Math.floor(width / zones)
    gh = Math.floor(height / zones)
    data.zones = ([] for i in [0...(gw * gh)])
    data.curve = []

    r1 = r2 = 0

    radii =
      _.flatten(
        for n in [0..data.kink]
          r1 = r2 or _.random(data.radius.min, data.radius.max)
          r2 =       _.random(data.radius.min, data.radius.max)
          len = (data.spline.length / data.kink)
          for j in [0..len]
            t = easie.cubicInOut(j / len, 0, 1, 1)
            r1 + (r2 - r1) * t
      )

    sequence steps =
      for p0, i in data.spline.slice(0, -1)
        do (p0, i) -> ->

          if i % 100 is 0
            ctx.beginPath()
            ctx.globalAlpha = 0.02
            # ctx.globalCompositeOperation = "source-over"
            ctx.fillStyle = data.colors.bg
            ctx.rect(0, 0, width, height)
            ctx.fill()
            ctx.globalAlpha = 1
            # ctx.globalCompositeOperation = "difference"

          p1 = data.spline[i + 1]
          dx = p1.x - p0.x
          dy = p1.y - p0.y

          t = (freq / 2 - i % freq) / (freq / 2)

          px = p0.x + dx * t
          py = p0.y + dy * t
          theta = (t * Math.PI * 2)
          rx = radii[Math.min(i, radii.length)]

          x = px + Math.cos(theta) * rx
          y = py + Math.sin(theta) * rx

          r = data.strokeWidth.max - data.strokeWidth.min
          r = data.strokeWidth.min + r * Math.abs(t) if data.nib
          r = Math.max(r, 2)

          zone = Math.floor(x / zones) + Math.floor(y / zones) * gw
          data.zones[zone]?[i] = {x, y}
          data.curve.push {x, y, r, theta}


          # redraw line at centre
          if p0.x > 0 and p0.y > 0 and p0.x < width and p0.y < height
            ctx.fillStyle = data.colors.line
            ctx.beginPath()
            ctx.arc(p0.x, p0.y, 2, 0, Math.PI * 2)
            ctx.fill()

          if x > 0 and y > 0 and x < width and y < height
            # ctx.globalAlpha = 0.02
            ctx.fillStyle = data.colors.bg
            ctx.beginPath()
            ctx.arc(x, y, 80, 0, Math.PI * 2)
            ctx.fill()
            ctx.globalAlpha = 1

            # ctx.globalAlpha = 0.2
            if i % 10 is 0
              xo = x + Math.cos(theta) * (r * .15)
              yo = y + Math.sin(theta) * (r * .15)
              ctx.fillStyle = data.colors.bg
              ctx.beginPath()
              ctx.arc(xo, yo, r * .9, 0, Math.PI * 2)
              ctx.fill()
              ctx.globalAlpha = 1

            ctx.fillStyle = data.colors.fg
            ctx.beginPath()
            for j in [0..80] when p = data.curve[i - j]
              xo = p.x
              yo = p.y
              ctx.moveTo(xo + r, yo)
              ctx.arc(xo, yo, r, 0, Math.PI * 2)
            ctx.fill()

            ctx.fillStyle = data.colors.fg
            ctx.beginPath()
            ctx.arc(x, y, r, 0, Math.PI * 2)
            ctx.fill()

  number: ({ width, height }, ctx, data) ->
    ctx.font      = "700 20px sans"
    ctx.fillStyle = data.colors.number
    ctx.beginPath()

    for { x, y }, i in data.line
      ctx.fillText(i, x, y)

  intersections: ({ width, height }, ctx, data) ->
    zones = data.zones
    intersections = _.chain(
      for zone in zones
        zone = _.compact(zone)
        for p0, i in zone
          p1 = zone[i + 1]
          i++
          for p2, j in zone when Math.abs(j - i) > 2
            p3 = zone[j + 1]
            j++
            if p0 and p1 and p2 and p3
              if helpers.intersection(
                p0.x, p0.y
                p1.x, p1.y
                p2.x, p2.y
                p3.x, p3.y
              )
                p0
    )
      .flatten()
      .compact()
      .uniq()
      .value()

    ctx.fillStyle = data.colors.bg
    # ctx.strokeStyle = data.colors.bg
    ctx.lineWidth = data.borderWidth
    ctx.lineCap = "round"
    # ctx.beginPath()
    # for {x, y} in intersections
    #   ctx.moveTo(x + 8, y)
    #   ctx.arc(x, y, 8, 0, Math.PI * 2)
    # ctx.stroke()


    console.log intersections

    # for zone, j in zones
    #   zone = _.compact(zone)
    toRedraw =
      for { x, y, r }, i in data.curve when q = _.find(intersections, {x, y})
        index = intersections.indexOf(q)
        min   = Math.max(i - data.strokeWidth.max, 0)
        max   = Math.min(i + data.strokeWidth.max, data.curve.length - 1)
        { index: i, path: data.curve[min + 1..max - 1] }

    # inOrder = _.sortBy(toRedraw, "index")
    inOrder = toRedraw
      .filter((e, i) -> i % 2 is 0)
      .concat(toRedraw.filter((e, i) -> i % 2 is 1))

    for { path } in inOrder
      ctx.strokeStyle = data.colors.bg
      ctx.beginPath()
      for { x, y, r, theta }, i in path
        ctx[if i is 0 then "moveTo" else "lineTo"](
          x + Math.cos(theta) * (r + data.borderWidth / 2)
          y + Math.sin(theta) * (r + data.borderWidth / 2)
        )

      for { x, y, r, theta }, i in path.reverse()
        ctx[if i is 0 then "moveTo" else "lineTo"](
          x - Math.cos(theta) * (r + data.borderWidth / 2)
          y - Math.sin(theta) * (r + data.borderWidth / 2)
        )

      ctx.stroke()

      for { x, y, r, theta }, i in path
        ctx.beginPath()
        ctx.fillStyle = data.colors.fg
        ctx.arc(x, y, r, 0, Math.PI * 2)
        ctx.fill()


  wrap: (method, { width, height }, data, args...) ->
    canvas        = document.createElement("canvas")
    ctx           = canvas.getContext("2d")
    canvas.width  = width
    canvas.height = height

    method(canvas, ctx, data, args...)
    ctx.getImageData(0, 0, canvas.width, canvas.height)
