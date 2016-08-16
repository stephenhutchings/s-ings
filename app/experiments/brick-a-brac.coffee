badge     = require("experiments/badge")
resample  = require("experiments/resample")
posterize = require("experiments/posterize")
bigCanvas = require("experiments/big-canvas")
sequence  = require("experiments/sequence")
wobble    = require("experiments/wobble")
layer     = require("experiments/layer")

maybe       = require("experiments/brick-a-brac/maybe")
drawWindow  = require("experiments/brick-a-brac/window")
drawRoof    = require("experiments/brick-a-brac/roof")
drawEscape  = require("experiments/brick-a-brac/window")
drawBalcony = require("experiments/brick-a-brac/balcony")

maybe = (chance = 0.5) -> Math.random() > (1 - chance)

dpi   = window.webkitDevicePixelRatio or window.devicePixelRatio or 1
scale = 1.75

position = (canvas, features) ->
  w = features.floors.w * features.brick.w
  h = (features.floors.h + features.border.amount * features.border.height) * features.brick.h

  roofH = features.roof.h + features.roof.base * features.brick.h
  roofH -= features.roof.h unless features.roof.style

  x = canvas.width  - w
  y = canvas.height - h * features.floors.amount + roofH
  x = Math.max(x, 0) / 2
  y = Math.max(y, 0) / 2

  { x, y, w, h }

module.exports =
  draw: ->
    { canvas, ctx } = bigCanvas(40)

    canvas.width  *= scale
    canvas.height *= scale

    features =
      brick:
        h: 4 * dpi
        w:  4 * dpi * 3

      floors:
        amount: _.random(4, 7)
        h:  _.random(27, 34) # rows of bricks
        w:  _.random(24, 48) # columns of bricks

      border:
        amount: _.random(0, 4)
        outset: _.random(4, 12)
        height: _.random(1, 4)

      hasEdge: maybe()

      sides:
        balconyStyle: _.sample ["strokes", "glass", "bars"]
        balconyBar: maybe()
        balconyInset: maybe(0.4)
        balconyHeight: _.random(10, 14)
        features: [
          maybe() and _.sample ["fire-escape", "balcony"]
          maybe() and _.sample ["fire-escape", "balcony"]
        ]

        width: _.random(1, 4) * 40

      roof:
        style: maybe(0.6) and _.sample ["triangular", "square"]
        h: _.random(2, 4) * 40
        inset: _.random(-2, 6)
        base: _.random(1, 4)
        edged: _.random(3)

      windows:
        amount: _.random(1, 4)
        w: _.random(3, 5)  # in bricks
        h: _.random(16, 26) # in bricks
        divisions: _.random(1, 3)
        topFrame: maybe()
        bottomFrame: maybe()
        frameInset: _.sample([0, 12, 14, 16])
        grid: _.random(-1, 1)
        gridInset: _.sample([0, 12])

    if features.border.amount > 2
      features.border.height = Math.min(features.border.height, 1.5)

    if features.windows.divisions > 2
      features.windows.grid = -1

    features.windows.h = Math.min(
      features.windows.h,
      features.floors.h - _.compact(
        [features.windows.topFrame, features.windows.bottomFrame]
      ).length * 2 - 2
    )

    features.windows.offsets =
      x: _.random(-2, 2) for [0...features.windows.amount]
      w: _.random(0, 2) for [0...features.windows.amount]
      grills: _.random(2, 6) for [0..features.windows.amount]
      gutters: maybe() and _.random(1, 12) for [0..features.windows.amount]

    console.log JSON.stringify features, null, 2

    sequence [
      =>
        ctx.fillStyle   = "#f4dabe"
        ctx.beginPath()
        ctx.rect(0, 0, canvas.width, canvas.height)
        ctx.fill()

      =>
        { x, y, w, h } = position(canvas, features)

        for floor in [0...features.floors.amount - 1]
          for feature, i in features.sides.features when feature
            fw   = features.sides.width
            fx   = if i is 0 then -fw else w
            draw = if feature is "fire-escape" then drawEscape else drawBalcony
            data = draw(features, {x, y, w: fw, h})
            fy   = y + h * floor
            fx   = x + fx
            layer(ctx, data, fx, fy)

      =>
        { x, y, w, h } = position(canvas, features)

        for floor in [0...features.floors.amount]
          data = @brick(features, floor)
          layer(ctx, data, x + (w - data.width) / 2, y + h * floor)
      =>
        { x, y, w, h } = position(canvas, features)

        data = drawRoof(features)
        layer(ctx, data, x + (w - data.width) / 2, y - data.height)

      =>
        { x, y, w, h } = position(canvas, features)
        ctx.fillStyle   = "#f4dabe"
        ctx.strokeStyle = "#00184d"
        ctx.lineWidth = wobble(4, 2)
        padding = wobble(80, 60)
        incline = wobble(20)

        x = x - padding
        w = w + padding * 2
        y = y + h * features.floors.amount + ctx.lineWidth / 2

        ctx.beginPath()
        ctx.moveTo(x,     y + incline)
        ctx.lineTo(x + w, y - incline)
        ctx.lineTo(x + w, y + 8)
        ctx.lineTo(x, y + 8)
        ctx.fill()

        ctx.beginPath()
        ctx.moveTo(x,     y + incline)
        ctx.lineTo(x + w, y - incline)
        ctx.stroke()

        if maybe()
          ctx.beginPath()
          ctx.lineWidth /= 2
          ctx.moveTo(x + _.random(20),     y + incline + 12)
          ctx.lineTo(x + w - _.random(20), y - incline + 12)
          ctx.stroke()

      =>
        margin = 20 * dpi * scale
        { width, height, data } = badge "brick-a-brac", margin, (c) ->
          fx = new CanvasEffects(c, {useWorker: false})
          fx.noise(12)
          posterize(c, 1.25 * dpi * scale)

        ctx.putImageData(
          data
          canvas.width - width - margin
          canvas.height - height - margin
        )
      =>
        fx = new CanvasEffects(canvas, {useWorker: false})
        fx.noise(12)
        # posterize(canvas, .5 * dpi * scale)
    ]

  brick: (features, floor) ->
    bw = features.brick.w
    bh = features.brick.h

    canvas = document.createElement("canvas")
    ctx    = canvas.getContext("2d")

    width =  features.floors.w * bw
    height = features.floors.h * bh

    canvas.width  = width  + features.border.outset * 2
    canvas.height = height + (features.border.amount * features.border.height) * bh

    ctx.strokeStyle = "#00184d"
    ctx.lineWidth = 4

    originX = features.border.outset
    originY = features.border.amount * features.border.height * bh

    # Sides
    ctx.beginPath()
    ctx.moveTo(originX, originY)
    ctx.lineTo(originX, originY + height)
    ctx.moveTo(originX + width, originY)
    ctx.lineTo(originX + width, originY + height)
    ctx.stroke()

    dark = []
    light = []

    # Bricks
    rows = Math.floor(height / bh)

    for i in [0...rows]
      ox = originX
      oy = originY

      ox += if i % 2 is 0 then 0 else bw / 2

      cols = Math.floor(width / bw) - (i % 2)

      if features.hasEdge
        ox += bw / 2
        cols -= 1

      for j in [0...cols]
        ctx.beginPath()
        ctx.lineWidth = wobble(2, 2)
        rect = [j * bw + ox, i * bh + oy, bw, bh]
        ctx.rect(rect...)

        if Math.random() > 0.5
          dark.push(rect)
        else
          light.push(rect)

        ctx.stroke()

    posterize(canvas, 8)

    for group, i in [dark, light]
      ctx.fillStyle = ["#00184d", "#fff"][i]
      for [x, y] in group
        ctx.beginPath()
        ctx.globalAlpha = Math.random() * .3
        ctx.rect(x, y, bw, bh)
        ctx.fill()

    ctx.globalAlpha = 1
    lastX = 0
    grills = []
    gutters = []

    # Windows
    for i in [0...features.windows.amount]
      split = (features.floors.w - features.windows.w) / features.windows.amount
      o = Math.round(split * (i + 0.5))
      o += features.windows.offsets.x[i]

      x = Math.max(originX + o * bw, originX + bw, lastX)
      y = originY + Math.floor((features.floors.h - features.windows.h) / 2) * bh
      w = (features.windows.w + features.windows.offsets.w[i]) * bw
      h = features.windows.h * bh

      y = Math.max(y, originY + ((if features.windows.topFrame then 2 else 0) + 1) * bh)
      w = Math.min(w, width - (x - originX) - bw)

      data = drawWindow(features.windows, { x, y, w, h })
      ctx.putImageData(data, x, y)

      if lastX <= x - bw * (features.windows.offsets.grills[i] + 2)
        grills.push [x - bw * (features.windows.offsets.grills[i] + 1), y]

      if lastX <= x - bw * (features.windows.offsets.gutters[i] + 2) and
         features.windows.offsets.gutters[i]
        gutters.push [x - bw * (features.windows.offsets.gutters[i] + 1), originY]

      lastX = x + w

    if width - bw + originX <= lastX + bw * (features.windows.offsets.grills[i + 1] + 1)
      grills.push [lastX + bw * features.windows.offsets.grills[i], y]

    if width - bw + originX <= lastX + bw * (features.windows.offsets.gutters[i + 1] + 1) and
       features.windows.offsets.gutters[i]
      gutters.push [lastX + bw * features.windows.offsets.gutters[i], originY]

    # Grills
    ctx.strokeStyle = "#f4dabe"
    ctx.fillStyle = "#00184d"
    ginset = 4
    for [x, y] in grills
      w = bw
      h = bh * 2
      iw = w - ginset * 2
      ih = h - ginset * 2
      ix = x + ginset
      iy = y + ginset
      ctx.beginPath()
      ctx.rect(x, y, w, h)
      ctx.fill()
      ctx.beginPath()

      # ctx.rect(ix, iy, iw, ih)
      for i in [0..3]
        ctx.moveTo ix + (iw / 3) * i, iy
        ctx.lineTo ix + (iw / 3) * i, iy + ih

      ctx.stroke()

    # Border
    ctx.strokeStyle = "#00184d"
    ctx.fillStyle = "#f4dabe"
    ctx.lineWidth = 4

    if features.border.amount
      for j in [0...features.border.amount]
        ctx.beginPath()
        dist = Math.abs((features.border.amount - 1) / 2 - j) / features.border.amount * 2
        ox = dist * features.border.outset
        ctx.rect(ox, bh * features.border.height * j, canvas.width - ox * 2, bh * features.border.height)
        ctx.fill()
        ctx.stroke()

        if j is features.border.amount - 1
          ctx.beginPath()
          ctx.moveTo(originX, bh * features.border.height * (j + 1) + 4)
          ctx.lineTo(originX + width, bh * features.border.height * (j + 1) + 4)
          ctx.lineWidth = 8
          ctx.globalAlpha = 0.5
          ctx.stroke()
          ctx.globalAlpha = 1


    # Gutters
    for [x, y] in gutters
      ctx.strokeStyle = "#00184d"
      ctx.fillStyle = "#f4dabe"

      gh = canvas.height
      if floor is features.floors.amount - 1
        gh -= bh * _.random(1, 4)

      ctx.beginPath()
      ctx.rect(x, 0, bh * 2, gh)
      ctx.fill()

      ctx.beginPath()
      ctx.moveTo(x, 0)
      ctx.lineTo(x, gh)
      ctx.lineWidth = 4
      ctx.stroke()

      ctx.beginPath()
      ctx.moveTo(x + bh * 2, 0)
      ctx.lineTo(x + bh * 2, gh)
      ctx.globalAlpha = 0.25
      ctx.lineWidth = 12
      ctx.stroke()
      ctx.globalAlpha = 1
      ctx.lineWidth = 4
      ctx.stroke()

      if floor is features.floors.amount - 1
        ctx.fillStyle = "#00184d"
        ctx.beginPath()
        ctx.lineWidth = 3
        ctx.moveTo(x, gh - bh - 16)
        ctx.lineTo(x + bh * 2, gh - bh - 16)
        ctx.stroke()

        ctx.beginPath()
        ctx.rect(x, gh - bh - 4, bh * 2, bh + 2)
        ctx.fill()

    mask = ctx.getImageData(0, 0, canvas.width, canvas.height)
    mask
