bigCanvas = require("experiments/big-canvas")
sequence  = require("experiments/sequence")
sortOrder = require("experiments/pos-or-neg")
posterize = require("experiments/posterize")

module.exports =
  draw: (options, done) ->
    { canvas, ctx } = bigCanvas(options)

    scale = options.scale or 1

    canvas.width  *= scale
    canvas.height *= scale

    window.canvas = canvas
    window.ctx = ctx

    points = []
    offset = []
    distance = canvas.width / 100
    radius = 1

    sequence [
      ->
        ctx.fillStyle   = "#ddd"
        ctx.beginPath()
        ctx.rect(0, 0, canvas.width, canvas.height)
        ctx.fill()

      ->
        ctx.fillStyle = "#000"
        ctx.beginPath()

        rows = Math.floor(canvas.height / distance)
        cols = Math.floor(canvas.width / distance)

        xo = (canvas.width  - cols * distance) / 2
        yo = (canvas.height - rows * distance) / 2

        for r in [1...rows]
          for c in [1...cols]
            x = c * distance + xo
            y = r * distance + yo
            ctx.moveTo(x, y)
            ctx.arc(x, y, radius, 0, Math.PI * 2)
            points.push({x,y})

        ctx.fill()

      ->

        ctx.lineWidth = 4

        ctx.beginPath()

        for p, i in points
          xo = if sortOrder(i) > 0 then -distance else distance
          yo = if sortOrder(~~Math.pow(i, 2)) > 0 then -distance else distance

          xo *= -1 if (p.x + xo > canvas.width  - distance) or (p.x + xo <= distance)
          yo *= -1 if (p.y + yo > canvas.height - distance) or (p.y + yo <= distance)

          ctx.moveTo(p.x, p.y)
          ctx.lineTo(p.x + xo, p.y + yo)

          offset.push([p.x + xo / 2, p.y + yo / 2])

        ctx.stroke()

      ->
        ctx.beginPath()
        r2 = distance / 2 #* Math.pow(2, 0.5)

        d1 = 1/Math.pow(2,0.5)
        d2 = 1 - d1

        t = 0

        for p, i in points
          d = if sortOrder(i / 2) > 0 then d1 else d2
          r2 = distance * d

          [xo, yo] = [p.x + distance / 2, p.y + distance / 2]

          [r,g,b,a] = ctx.getImageData(xo, yo, 1, 1).data
          # r = sortOrder(i) * 255

          if r > 128 and xo < canvas.width - distance and yo < canvas.height - distance
            ctx.moveTo(xo + r2, yo)
            ctx.arc(xo, yo, r2, 0, Math.PI * 2)

        ctx.stroke()

      ->
        posterize(canvas, 2, "grayscale")

      done
    ]
