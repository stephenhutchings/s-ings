# coffeelint: disable:max_line_length

bigCanvas = require("experiments/big-canvas")
sequence  = require("experiments/sequence")
helpers   = require("experiments/line/helpers")
posterize = require("experiments/posterize")
resample  = require("experiments/resample")
shortest  = require("experiments/line/shortest-path")

dpi   = window.webkitDevicePixelRatio or window.devicePixelRatio or 1
scale = null

module.exports =
  draw: (options, done) ->
    { canvas, ctx } = bigCanvas(options)

    scale = options.scale or 2.5

    canvas.width  *= scale
    canvas.height *= scale

    shapes = [[]]

    points = []
    offset = 200

    sequence [
      ->
        gradient = ctx.createLinearGradient(0, 0, canvas.width, 0)
        gradient.addColorStop(0, 'white')
        gradient.addColorStop(1, 'red')

        ctx.fillStyle = gradient
        ctx.fillStyle = "#ddd"
        ctx.beginPath()
        ctx.rect(0, 0, canvas.width, canvas.height)
        ctx.fill()

      ->
        return
        ctx.fillStyle = "#000"
        ctx.globalAlpha = 0.1

        for point in points
          ctx.beginPath()
          ctx.arc(point.x, point.y, 8, 0, Math.PI * 2)
          ctx.closePath()
          ctx.fill()

      ->
        return

        list = helpers.nearest points, {x: canvas.width / 2, y: canvas.height / 2}

        for point in list.reverse()
          arr = _.last(shapes)
          arr.push(point)
          if arr.length > _.random(3, 4)
            shapes.push([])

      ->
        return
        ctx.globalAlpha = 1
        ctx.lineCap = "round"

        sequence (
          for shape in shapes when shape.length > 2
            do (shape) -> ->

              ctx.lineWidth = 80
              ctx.strokeStyle = "#fff"

              ctx.beginPath()
              path = helpers.catmullRomBezier(shape, 0.25)
              p = new Path2D("M#{path}")
              ctx.stroke(p)

              ctx.lineWidth = 40
              ctx.strokeStyle = "#000"
              ctx.beginPath()
              ctx.stroke(p)

        )

      ->
        # return
        dist = 120
        list = helpers.makeGrid(canvas.width - offset * 2, canvas.height - offset * 2, dist)

        ctx.fillStyle = "#000"
        ctx.lineCap = "round"
        ctx.lineWidth = 20
        ctx.strokeStyle = "#000"

        for point in list
          ctx.beginPath()
          angle = Math.random() * Math.PI
          x = Math.cos(angle) * (dist / 3)
          y = Math.sin(angle) * (dist / 3)

          ctx.moveTo(offset + point.x - x, offset + point.y - y)
          ctx.lineTo(offset + point.x + x, offset + point.y + y)

          ctx.stroke()

          points.push x: offset + point.x - x, y: offset + point.y - y
          points.push x: offset + point.x + x, y: offset + point.y + y

      ->
        # return
        ctx.fillStyle = "#ddd"
        ctx.rect(0, 0, canvas.width, canvas.height)
        ctx.fill()

        ctx.fillStyle = "#000"
        ctx.lineCap = "round"
        ctx.lineWidth = 30 + Math.random() * 30
        ctx.strokeStyle = "black"

        ctx.beginPath()

        remaining = _.clone(points)

        for p0, i in points
          continue if remaining.length < 4 or
            Math.random() > 0.95 or
            (p0.y >= canvas.height - offset * 2 and Math.random() > 0.85) or
            (p0.x >= canvas.width - offset * 2 and Math.random() > 0.85)

          do (p0, i) ->
            [p0, p1, p2, p3] = helpers.nearest(remaining, p0)
            remaining = _.without(remaining, p0)
            ctx.beginPath()
            ctx.lineWidth = 30 + Math.random() * 30
            ctx.moveTo(p0.x, p0.y)
            ctx.lineTo(p1.x, p1.y)

            ctx.stroke()

      -> posterize(canvas, 24)
      # -> resample(ctx, canvas, scale)
      -> done canvas
    ]

