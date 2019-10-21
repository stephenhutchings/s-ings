bigCanvas = require("experiments/big-canvas")
sequence  = require("experiments/sequence")
sortOrder = require("experiments/pos-or-neg")

value = (point) ->
  vals =
    "⬉": 1
    "⬈": 2
    "⬊": 4
    "⬋": 8

  _.uniq(point.joins).reduce (m, e) ->
    m + vals[e]
  , 0

complement = (key) ->
  (vals =
    "⬉": "⬊"
    "⬈": "⬋"
    "⬊": "⬉"
    "⬋": "⬈"
  )[key]

avail = (point, points, cols) ->
  row = point.r
  col = point.c
  mod = row % 2

  isLEdge = mod is 0 and col is 0
  isREdge = mod is 0 and col is cols

  _.reduce "⬉⬈⬋⬊".split(""), (m, dir) ->
    if ((dir is "⬉" or dir is "⬋") and isLEdge) or
       ((dir is "⬈" or dir is "⬊") and isREdge)
      m

    pos =
      switch dir
        when "⬉" then {r: row - 1, c: col - (1 - mod)}
        when "⬋" then {r: row + 1, c: col - (1 - mod)}
        when "⬈" then {r: row - 1, c: col + mod}
        when "⬊" then {r: row + 1, c: col + mod}

    p = _.find points, pos
    m[dir] = p if p?.a is 1

    m
  , {}

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

    dh = 12 * scale
    dw = 24 * scale

    rows = Math.floor(canvas.height / dh - 1) * 2 + 1
    cols = Math.floor(canvas.width / dw - 1)

    sequence [
      ->
        ctx.fillStyle   = "#000"
        ctx.beginPath()
        ctx.rect(0, 0, canvas.width, canvas.height)
        ctx.fill()

      ->
        ctx.font = "9px William"
        ctx.textAlign = "center"
        ctx.fillStyle = "#fff"
        ctx.beginPath()

        xo = 0
        yo = 0

        for r in [0...rows]
          mod = 1 - r % 2
          for c in [0...cols + mod]
            x = (c + 0.5 * (1 + r % 2)) * dw + Math.random() * 0
            y = (r + 1) * (dh / 2) + Math.random() * 0
            ctx.moveTo(x, y)
            # ctx.arc(x, y, radius, 0, Math.PI * 2)
            points.push({x,y,r,c, a:1, i: points.length + 1})
            ctx.fillText("#{points.length}", x, y + 2)

        ctx.fill()

      ->
        ctx.beginPath()
        ctx.lineWidth = 1
        ctx.strokeStyle = "red"

        for point in points
          if (point.c is cols and point.r % 2 is 0) or point.r is rows - 1
            ctx.moveTo(point.x + dw * 0, point.y + dh / 2)
            ctx.lineTo(point.x + dw * 0.5, point.y)

          ctx.moveTo(point.x + dw * 0, point.y + dh / 2)
          ctx.lineTo(point.x - dw * 0.5, point.y)

          if (point.c is cols and point.r % 2 is 0) or point.r is 0
            ctx.moveTo(point.x + dw * 0, point.y - dh / 2)
            ctx.lineTo(point.x + dw * 0.5, point.y)

          ctx.moveTo(point.x + dw * 0, point.y - dh / 2)
          ctx.lineTo(point.x - dw * 0.5, point.y)

        ctx.stroke()

      ->
        stack = [points[0]]

        ctx.globalAlpha = 0.5
        ctx.lineWidth = distance / 4
        ctx.strokeStyle = "red"
        ctx.beginPath()

        return new Promise (res, rej) ->
          explore = ->
            if Math.random() > 0.9
              prev = _.sample stack
            else
              prev = _.last stack

            opts = avail(prev, _.without(points, stack...), cols)
            rkey = _.sample(_.keys(opts))
            next = opts[rkey]

            if next
              ctx.beginPath()
              ctx.moveTo(prev.x,prev.y)
              ctx.lineTo(next.x,next.y)
              ctx.stroke()

              next.a = 0
              prev.joins ?= []
              next.joins ?= []

              prev.joins.push(rkey)
              next.joins.push(complement(rkey))

              stack.push(next)
            else
              stack.splice(stack.indexOf(prev), 1)

            if stack.length > 0
              explore()
            else
              res()

          explore()
          ctx.stroke()

      ->
        # return
        ctx.globalAlpha = 1
        ctx.rect(0, 0, canvas.width, canvas.height)
        ctx.fillStyle = "#333"
        ctx.fill()

        for i in [0..15]
          do (i) ->
            tiles = points.filter (p) ->
              value(p) is i

            console.log tiles
            img = new Image()
            img.src = "./tiles/tile-#{i}.svg"
            img.onload = ->
              for tile in tiles
                ctx.drawImage(img, tile.x - dw / 2, tile.y - dh / 2, dw, dh)



        return



        # while _.filter(points, { a: 1 }).length > 0 and count < 3000
        #   count++
        #   point.a = 0
        #   list.push(point)

        #   options = avail(point, points, cols)
        #   choice  = _.sample(_.keys(options))
        #   next = options[choice]

        #   if next
        #     stack.push next
        #     # list.push("move")
        #     point = next
        #   else
        #     # console.log "pop"
        #     # stack.pop()

        #     ctx.fillStyle = "blue"
        #     ctx.beginPath()
        #     ctx.moveTo(point.x + 5, point.y)
        #     ctx.arc(point.x, point.y, 10, 0, Math.PI * 2)
        #     ctx.fill()
        #     stack.pop() if _.last(list) is _.last(stack)

        #     point = stack.pop()


        console.log _.pluck(list, "i")


        ctx.fillStyle = "cyan"
        ctx.beginPath()
        ctx.moveTo(list[0].x + 5, list[0].y)
        ctx.arc(list[0].x, list[0].y, 10, 0, Math.PI * 2)
        ctx.fill()

        ctx.globalAlpha = 0.5
        ctx.lineWidth = distance / 4
        ctx.strokeStyle = "red"
        ctx.beginPath()
        ctx.moveTo(list[0].x, list[0].y)

        for p, l in list.slice(1)
          # ctx.moveTo(p.j.x, p.j.y) if p.j
          # ctx.lineTo(p.x, p.y)
          ctx[if p.j then "moveTo" else "lineTo"](p.x, p.y)
          ctx.arc(p.x,p.y,5,0,Math.PI * 2) if p.j

        ctx.stroke()


        return

        # ctx.beginPath()
        # ctx.fillStyle = "white"

        # for line in lines
        #   for p in [line[0], line.slice(-1)[0]]
        #     ctx.moveTo(p.x - dw * 0.25, p.y)
        #     ctx.lineTo(p.x, p.y + distance * 0.125)
        #     ctx.lineTo(p.x + dw * 0.25, p.y)
        #     ctx.lineTo(p.x, p.y - distance * 0.125)

        # ctx.fill()


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
