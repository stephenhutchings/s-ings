bigCanvas = require("experiments/big-canvas")
sequence  = require("experiments/sequence")
sortOrder = require("experiments/pos-or-neg")

module.exports =
  draw: (options, done) ->
    { canvas, ctx } = bigCanvas(options)

    scale = options.scale or 1

    options.distance *= scale

    canvas.width  *= scale
    canvas.height *= scale

    window.canvas = canvas
    window.ctx = ctx

    points = []
    offset = []
    distance = options.distance or canvas.width / 30
    radius = 1

    dh = distance
    dw = distance * 1.25

    rows = Math.floor(canvas.height / dh)
    cols = Math.floor(canvas.width / dw)

    sequence [
      ->
        ctx.fillStyle   = "#000"
        ctx.beginPath()
        ctx.rect(0, 0, canvas.width, canvas.height)
        ctx.fill()

      ->
        ctx.fillStyle = "#fff"
        ctx.beginPath()

        xo = (canvas.width  - cols * dw) / 2
        yo = (canvas.height - rows * dh) / 2



        for r in [1...rows]
          for c in [1...cols]
            x = c * dw + xo
            y = r * dh + yo
            ctx.moveTo(x, y)
            ctx.arc(x, y, radius, 0, Math.PI * 2)
            points.push({x,y})

        ctx.fill()

      ->
        list  = []
        lines = []

        while list.length < points.length
          line  = []

          point = _.sample(_.without(points, list...))

          while point and list.indexOf(point) < 0
            line.push(point)
            list.push(point)

            idx = points.indexOf(point)
            row = Math.floor idx / rows
            mod = 1

            for dir in _.shuffle "NSEW"
              if (dir is "W" and (idx % (cols - 1)) is 0) or
                 (dir is "E" and (idx % (cols - 1)) is cols - 2) or
                 (dir is "S" and (idx % (cols - 1)) is 0 and mod) or
                 (dir is "N" and (idx % (cols - 1)) is cols - 2 and mod)
                continue


              i =
                switch dir
                  when "E" then idx + 1
                  when "W" then idx - 1
                  when "N" then idx - (cols - 1 - mod)
                  when "S" then idx + (cols - 1 - mod)

              p = points[i]

              if p and list.indexOf(p) < 0
                point = p
                break

          lines.push(line)

        ctx.beginPath()
        ctx.lineWidth = distance / 4


        for line in lines
          ctx.moveTo(line[0].x, line[0].y)

          for point in line.slice(1)
            ctx.lineTo(point.x , point.y)

          # ctx.lineTo(line[0].x, line[0].y)

        # for line in lines
        #   f = line.filter (p, i, a) -> p.y > (a[i + 1]?.y or -1)
        #   pf = _.sample(line)

        #   ctx.moveTo(pf.x, pf.y)
        #   ctx.lineTo(pf.x + distance, pf.y)

        ctx.strokeStyle = "#fff"
        ctx.stroke()


        ctx.beginPath()
        ctx.fillStyle = "white"

        for line in lines
          for p in [line[0], line.slice(-1)[0]]
            ctx.moveTo(p.x - dw * 0.25, p.y + distance * 0.125)
            ctx.lineTo(p.x + dw * 0.0, p.y + distance * 0.125)
            ctx.lineTo(p.x + dw * 0.25, p.y - distance * 0.125)
            ctx.lineTo(p.x - dw * 0.0, p.y - distance * 0.125)

        ctx.fill()


        ctx.beginPath()
        ctx.lineWidth = 1
        ctx.strokeStyle = "red"

        for point in points
          ctx.moveTo(point.x + dw * 0, point.y + dh / 2)
          ctx.lineTo(point.x + dw * 1, point.y + dh / 2)

          ctx.moveTo(point.x + dw * 0, point.y + dh / 2)
          ctx.lineTo(point.x + dw * 1, point.y - dh / 2)

          ctx.moveTo(point.x + dw * 0, point.y + dh / 2)
          ctx.lineTo(point.x + dw * 0, point.y - dh / 2)

        ctx.stroke()


        return
        ctx.beginPath()
        ctx.lineWidth = 2
        ctx.strokeStyle = "red"

        for line in lines
          for point in line
            ctx.moveTo(point.x - distance / 4, point.y + distance / 4)
            ctx.lineTo(point.x + distance / 4, point.y + distance / 1)

            ctx.moveTo(point.x + distance / 4, point.y + distance / 4)
            ctx.lineTo(point.x + distance / 2, point.y + distance / 1)

        ctx.stroke()


      done
    ]
