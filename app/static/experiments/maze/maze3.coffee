# coffeelint: disable:max_line_length

bigCanvas = require("experiments/big-canvas")
sequence  = require("experiments/sequence")
sortOrder = require("experiments/pos-or-neg")
posterize = require("experiments/posterize")

value = (point) ->
  vals =
    "N": 1
    "E": 2
    "S": 4
    "W": 8

  _.uniq(point.joins).reduce (m, e) ->
    m + vals[e]
  , 0

complement = (key) ->
  (vals =
    "N": "S"
    "W": "E"
    "S": "N"
    "E": "W"
  )[key]

move = (point, dir) ->
  row = point.r
  col = point.c
  switch dir
    when "N" then {r: row - 1, c: col + 1}
    when "W" then {r: row + 0, c: col - 1}
    when "S" then {r: row + 1, c: col - 1}
    when "E" then {r: row + 0, c: col + 1}
    when "X" then {r: row - 1, c: col + 0}

avail = (point, points, cols, rows) ->
  isLEdge = point.c is 0
  isREdge = point.c is cols

  opts = "NWSE"
  # opts += "X" if Math.random() > 0.5

  _.reduce opts.split(""), (m, dir) ->
    # if ((dir is "E" or dir is "N") and isLEdge) or
    #    ((dir is "W" or dir is "S") and isREdge)
    #   m

    pos = move(point, dir)
    pos.r = pos.r % rows
    pos.c = pos.c % cols
    p = _.find points, move(point, dir)
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
    tiles = []

    solution = []

    dh = 20 * scale
    dw = 24 * scale

    rows = Math.floor(canvas.height / dh - 1)
    cols = Math.floor(canvas.width / dw - 1)

    sequence [
      # Fill canvas
      ->
        ctx.fillStyle   = "#000"
        ctx.beginPath()
        ctx.rect(0, 0, canvas.width, canvas.height)
        ctx.fill()

      # Create points
      ->
        xo = 0
        yo = 0

        for r in [0...rows - 1]
          for c in [1..cols]
            x = (c) * dw + Math.random() * 0
            y = (r + 1.5) * dh + Math.random() * 0

            isEdge = (c is 1 or c is cols) and r isnt rows - 2

            points.push {
              i: points.length + 1
              a: +not(isEdge and Math.random() > 0.5)
              x, y, r, c
            }

        points.unshift
          i: 0
          a: 1
          x: 0, y: dh * 1.5, r: 0, c: 0

        points.push
          i: points.length
          a: 1
          x: canvas.width, y: dh * (rows - 2 + 1.5), r: rows - 2, c: cols + 1

        console.log points


      # Label points
      ->
        ctx.font = "#{6 * options.scale}px William"
        ctx.textAlign = "center"
        ctx.fillStyle = "#fff"
        ctx.beginPath()

        for point in points
          ctx.fillText(point.i, point.x, point.y + 2)

        ctx.fill()

      # Draw grid
      ->
        ctx.beginPath()
        ctx.lineWidth = 1
        ctx.globalAlpha = 0.3
        ctx.strokeStyle = "white"

        for point in points
          ctx.moveTo(point.x + dw * 0, point.y + dh / 2)
          ctx.lineTo(point.x + dw * 1, point.y + dh / 2)

          ctx.moveTo(point.x + dw * 1, point.y - dh * 0.5)
          ctx.lineTo(point.x + dw * 0, point.y + dh * 0.5)

        ctx.stroke()

      # Draw maze
      ->
        stack = [points[0]]
        solved = false

        ctx.globalAlpha = 0.95
        ctx.lineWidth = distance / 4
        ctx.strokeStyle = "white"
        ctx.beginPath()

        goal =
          c: cols
          r: rows - 2

        return new Promise (res, rej) ->
          explore = ->
            if Math.random() > 0.85
              prev = _.sample(stack.slice(0, -1)) or stack[0]
            else
              prev = _.last stack

            unless solved
              solution.push prev

            opts = avail(prev, _.without(points, stack...), cols, rows)
            keys = _.keys(opts)
            # keys = keys.concat(["W", "W"]) if _.include keys, "W"
            # keys = keys.concat(["E", "E"]) if _.include keys, "E"
            rkey = _.sample(keys)
            next = opts[rkey]

            if (prev.c is goal.c and prev.r is goal.r) and not solved
              solved = true

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
              window.setTimeout explore, 1
            else
              res()

          explore()
          ctx.stroke()

      # Remove branches from solution
      # Filter solution for unique points, then remove discontinguous nodes
      # starting from the back
      ->
        solution =
          solution
            .filter((e, i, a) -> a.indexOf(_.find(a, {i: e.i})) is i)
            .reverse()

        do explore = (i = 0) ->
          [prev, next] = solution[i..i + 1]

          unless prev? and next?
            return

          isContiguous = false

          for j in prev.joins
            pos = move(prev, j)
            if next.r is pos.r and next.c is pos.c
              isContiguous = true
              break

          if isContiguous
            explore(i + 1)
          else
            solution.splice(i + 1, 1)
            explore(i)

      # Load image tiles
      ->
        new Promise (res) ->
          count = 1
          for i in [count..15]
            do (i) ->
              img = new Image()
              img.src = "./tiles/til-#{i}.png"
              img.onload = ->
                count++
                tiles[i] = img
                if count is 15
                  res()

      # Fill canvas
      ->
        ctx.globalAlpha = 1
        ctx.beginPath()
        ctx.rect(0, 0, canvas.width, canvas.height)
        ctx.fillStyle = "#333"
        ctx.fill()

      # Draw tiles
      ->
        for point in points
          img = tiles[value(point)]
          if img?
            ctx.drawImage(img, point.x - dw, point.y - dh / 2, dw * 2, dh * 1.35)
          else
            console.log value(point)


      # Draw solution
      ->
        ctx.globalAlpha = 1
        ctx.strokeStyle = "#333"
        ctx.lineWidth = distance / 8
        ctx.beginPath()
        ctx.moveTo(solution[0].x - scale * 0.5, solution[0].y)

        for point, j in solution
          ctx.lineTo(point.x - scale * 0.5, point.y)

        ctx.stroke()

      done
    ]
