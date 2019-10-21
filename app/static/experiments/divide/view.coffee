# coffeelint: disable:max_line_length

bigCanvas = require("experiments/big-canvas")
sequence  = require("experiments/sequence")
helpers   = require("experiments/line/helpers")
posterize = require("experiments/posterize")
shortest  = require("experiments/line/shortest-path")

dpi   = window.webkitDevicePixelRatio or window.devicePixelRatio or 1
scale = null

module.exports =
  draw: (options, done) ->
    { canvas, ctx } = bigCanvas(options)

    scale = options.scale or 2.5

    canvas.width  *= scale
    canvas.height *= scale

    sequence [
      ->
        ctx.fillStyle   = "#ddd"
        ctx.beginPath()
        ctx.rect(0, 0, canvas.width, canvas.height)
        ctx.fill()

      ->
        x = y = buffer = canvas.width * 0.1
        w = canvas.width - x * 2
        h = canvas.height - y * 2
        rects = [{ w, h, x, y }]
        iterations = (13)

        divs = _.sample([
          # [1 / 3, 1 / 2, 2 / 3]
          # [.1, .3, .6]
          # [.5]
          [.4, .6]
          # [.1]
        ])

        for i in [0...iterations]
          next = []

          # Make divisions
          for rect, j in rects
            div = _.sample(divs)

            r1 = _.clone(rect)
            r2 = _.clone(rect)

            if rect.w / rect.h > (4 / 3)
              r1.w *= div
              r2.x += div * rect.w
              r2.w -= r1.w
            else
              r1.h *= div
              r2.y += div * rect.h
              r2.h -= r1.h

            # if j % 2 is 0
            next.push(r1)
            next.push(r2)
            # else
            #   next.push(r2)
            #   next.push(r1)

          rects = next

        console.log rects

        ctx.beginPath()

        for { x, y, w, h } in rects
          ctx.rect(x, y, w, h)
          ctx.moveTo(x, y)
          ctx.lineTo(x + w, y + h)
          ctx.moveTo(x + w, y)
          ctx.lineTo(x, y + h)

        # ctx.stroke()

        ctx.beginPath()
        ctx.lineWidth = 10

        line =
          for { x, y, w, h }, i in rects.slice(0, -1)
            x: x + w / 2, y: y + h / 2

        line = _.compact(line)

        line.unshift(
          x: line[0].x + (line[1].x - line[0].x)
          y: line[0].y + (line[1].y - line[0].y)
        )

        line.push(
          x: line.slice(-2)[0].x + (line.slice(-2)[1].x - line.slice(-2)[0].x)
          y: line.slice(-2)[0].y + (line.slice(-2)[1].y - line.slice(-2)[0].y)
        )

        spline = line
        spline = helpers.spline(spline, 5)
        # spline = helpers.simplify spline, 2, true

        ctx.fillStyle = "#fff"
        # ctx.lineWidth = 8
        # bf = ctx.lineWidth * 16

        instructions =
          for p1, i in spline.slice(1, -1)
            do (i) -> ->

              ctx.lineWidth = 8
              bf = ctx.lineWidth * 16

              # bf += ctx.lineWidth * (if Math.random() > 0.5 then 4 else -4)
              bf = Math.min(Math.max(bf, buffer / 30), buffer)
              [p1, p2] = spline[i..i + 1]

              # if Math.sqrt(Math.pow(p2.x - p1.x, 2) + Math.pow(p2.y - p1.y, 2)) > buffer
              #   return

              ctx.beginPath()
              ctx.moveTo(p1.x - bf / 2, p1.y - bf / 2)
              ctx.lineTo(p2.x - bf / 2, p2.y - bf / 2)
              ctx.lineTo(p2.x + bf / 2, p2.y + bf / 2)
              ctx.lineTo(p1.x + bf / 2, p1.y + bf / 2)

              ctx.fill()

              ctx.strokeStyle = "black"
              ctx.beginPath()

              if false
                # Draw length ways
                sub = helpers.interpolate([p1, p2], .025)

                for p, j in sub
                  ctx.moveTo(p.x - bf / 2, p.y - bf / 2)
                  ctx.lineTo(p.x + bf / 2, p.y + bf / 2)
              else
                n = ctx.lineWidth * 2
                for j in [bf / -(2 * n)...bf / (2 * n)]
                  ctx.beginPath()
                  ctx.moveTo(p1.x + j * n, p1.y + j * n )
                  ctx.lineTo(p2.x + j * n, p2.y + j * n )
                  ctx.lineWidth = 7 * (1 - ((j * n) / bf))
                  ctx.stroke()


        sequence(instructions)

          # ctx.strokeStyle = "#fff"
          # ctx.beginPath()

          # ctx.moveTo(p1.x - buffer / 2, p1.y - buffer / 2)
          # ctx.lineTo(p2.x - buffer / 2, p2.y - buffer / 2)
          # ctx.stroke()

        # ctx.fillStyle    = "red"
        # ctx.strokeStyle  = "#ddd"
        # ctx.textAlign    = "center"
        # ctx.textBaseline = "middle"
        # ctx.font         = "700 40px sans"

        # for { x, y, w, h }, i in rects
        #   ctx.fillText(i, x + w / 2, y + h / 2)

      # -> posterize(canvas, 10, "grayscale")

      done
    ]
