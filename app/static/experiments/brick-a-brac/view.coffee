# coffeelint: disable:max_line_length

badge     = require("experiments/badge")
resample  = require("experiments/resample")
posterize = require("experiments/posterize")
bigCanvas = require("experiments/big-canvas")
sequence  = require("experiments/sequence")
wobble    = require("experiments/wobble")
layer     = require("experiments/layer")
frame     = require("experiments/frame")

maybe       = require("experiments/brick-a-brac/utils/maybe")
drawWindow  = require("experiments/brick-a-brac/utils/window")
drawRoof    = require("experiments/brick-a-brac/utils/roof")
drawEscape  = require("experiments/brick-a-brac/utils/escape")
drawBalcony = require("experiments/brick-a-brac/utils/balcony")
drawGround  = require("experiments/brick-a-brac/utils/ground")

maybe = (chance = 0.5) -> Math.random() > (1 - chance)

dpi   = window.webkitDevicePixelRatio or window.devicePixelRatio or 1
scale = null

position = (canvas, features) ->
  w = features.floors.w * features.brick.w
  h = (features.floors.h + features.border.amount * features.border.height) * features.brick.h

  roofH = features.roof.h + features.roof.base * features.brick.h
  roofH -= features.roof.h unless features.roof.style

  x = canvas.width  - w
  y = canvas.height - (h * features.floors.amount + features.ground.h * 3 + features.ground.baseH * features.brick.h) + roofH
  x = Math.max(x, 0) / 2
  y = Math.max(y, 0) / 2

  { x, y, w, h }

module.exports =
  draw: (options, done) ->
    { canvas, ctx } = bigCanvas(options)

    scale = options.scale or 2#.5

    canvas.width  *= scale
    canvas.height *= scale

    features =
      brick:
        h: 6 * dpi
        w: 6 * dpi * 3

      floors:
        amount: _.random(4, 7)
        h:  _.random(29, 36) # rows of bricks
        w:  _.random(24, 48) # columns of bricks

      border:
        amount: _.random(0, 4)
        outset: _.random(4, 12)
        height: _.random(1, 4)

      ground:
        h:       _.random(5, 40)
        kerbH:   _.random(12, 16)
        inset:   _.random(1, 10)
        outset:  wobble(80, 60)
        incline: wobble(20)
        baseH:   _.random(4) * 2
        baseW:   _.random(2, 8)

      hasEdge: maybe()

      sides:
        balconyStyle: _.sample ["strokes", "glass", "bars"]
        balconyBar: maybe()
        balconyInset: maybe(0.4)
        balconyHeight: _.random(10, 14)
        balconyWidth: _.random(1, 4) * 40
        escapeWidth: _.random(3, 4) * 40

        features: [
          maybe() and _.sample ["escape", "balcony"]
          maybe() and _.sample ["escape", "balcony"]
        ]

      roof:
        style: maybe(0.6) and _.sample ["triangular", "square"]
        h: _.random(2, 4) * 40
        inset: _.random(-2, 6)
        base: _.random(1, 4)
        edged: _.random(3)
        pipe: _.random(3)
        aerial: maybe()

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

      gutters:
        y: _.random(12)
        h: _.random(2)
        rainTrap: maybe(0.7) and {
          outset: _.random(8, 20)
          top: _.random(16, 24)
          bottom: _.random(16, 24)
        }

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

    { x, y, w, h } = position(canvas, features)

    wo = w + 1000
    ho = h * features.floors.amount + 1000

    if wo > canvas.width or ho > canvas.height
      s = Math.max(wo / canvas.width, ho / canvas.height)
      features.brick.h /= s
      features.brick.w /= s
      features.roof.h  /= s
      features.sides.balconyWidth /= s
      features.sides.escapeWidth  /= s
      { x, y, w, h } = position(canvas, features)

    sequence [
      ->
        ctx.fillStyle   = "#ddd"
        ctx.beginPath()
        ctx.rect(0, 0, canvas.width, canvas.height)
        ctx.fill()

      ->
        sequence _.flatten(
          for floor in [0...features.floors.amount - 1].reverse()
            for feature, i in features.sides.features when feature
              do (feature, i, floor) -> ->
                fw   = features.sides["#{feature}Width"]
                fx   = if i is 0 then -fw else w
                draw = if feature is "escape" then drawEscape else drawBalcony
                data = draw(features, {x, y, w: fw, h}, i, floor)
                fy   = y + h * floor
                fx   = x + fx
                layer(ctx, data, fx, fy)
        ), 0, "Features"

      =>
        sequence(
          for floor in [0...features.floors.amount]
            do (floor) => =>
              data = @brick(features, floor)
              layer(ctx, data, x + (w - data.width) / 2, y + h * floor)
          , 0, "Floors"
        )
      ->
        { x, y, w, h } = position(canvas, features)

        data = drawRoof(features)
        layer(ctx, data, x + (w - data.width) / 2, y - data.height)

      ->
        layer ctx, frame(canvas, 20 * scale)

      ->
        fx = new CanvasEffects(canvas, {useWorker: false})
        posterize(canvas, 2, [
          [40, 40, 40]
          [210, 210, 210]
          [255, 255, 255]
          [180,180,180]
        ])

      ->
        data = drawGround(features, { w })
        layer(ctx, data, x + (w - data.width) / 2, y + h * features.floors.amount)

      ->
        margin = 24 * dpi * scale
        { width, height, data } = badge margin / dpi, (c) ->
          fx = new CanvasEffects(c, {useWorker: false})
          fx.noise(12)
          posterize(c, 1.25 * dpi * scale, [
            [40, 40, 40]
            [210, 210, 210]
            [255, 255, 255]
            [180,180,180]
          ])

        ctx.putImageData(
          data
          (canvas.width - width) / 2
          canvas.height - height - margin
        )

      -> resample(ctx, canvas, scale)
      -> done canvas

    ], 0, "Building"

  brick: (features, floor) ->
    bw = features.brick.w
    bh = features.brick.h

    canvas = document.createElement("canvas")
    ctx    = canvas.getContext("2d")

    width =  features.floors.w * bw
    height = features.floors.h * bh

    canvas.width  = width  + features.border.outset * 2
    canvas.height = height + (features.border.amount * features.border.height) * bh

    ctx.strokeStyle = "#000"
    ctx.lineWidth = bh / 2

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
        ctx.lineWidth = wobble(bh / 4, bh / 4)
        rect = [j * bw + ox, i * bh + oy, bw, bh]
        ctx.rect(rect...)

        if Math.random() > 0.5
          dark.push(rect)
        else
          light.push(rect)

        ctx.stroke()

    # posterize(canvas, 8, "grayscale")

    for group, i in [dark, light]
      ctx.fillStyle = ["#000", "#fff"][i]
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

      y = Math.max(y, originY + ((if features.windows.topFrame then 2 else 0)) * bh) - bh
      w = Math.min(w, width - (x - originX) - bw)

      data = drawWindow(features.windows, { x, y, w, h })
      ctx.putImageData(data, x, y)

      if features.windows.bottomFrame
        ctx.beginPath()
        ctx.fillStyle = "#000"
        ctx.globalAlpha = 0.3
        ctx.rect(x, y + data.height, data.width, bh)
        ctx.fill()
        ctx.globalAlpha = 1

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
    ctx.strokeStyle = "#ddd"
    ctx.fillStyle = "#000"
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
    ctx.strokeStyle = "#000"
    ctx.fillStyle = "#ddd"
    ctx.lineWidth = bh / 2

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
          ctx.lineWidth = bh
          ctx.globalAlpha = 0.5
          ctx.stroke()
          ctx.globalAlpha = 1

    # Gutters
    { outset, top, bottom } = features.gutters.rainTrap
    for [x, y] in gutters
      ctx.strokeStyle = "#000"
      ctx.fillStyle = "#ddd"

      gh = canvas.height
      gw = bh * 2
      if floor is features.floors.amount - 1
        gh -= bh * _.random(1, 4)

      ctx.beginPath()
      ctx.rect(x, 0, gw, gh)
      ctx.fill()

      ctx.beginPath()
      ctx.moveTo(x, 0)
      ctx.lineTo(x, gh)
      ctx.lineWidth = bh / 2
      ctx.stroke()

      if floor is 0 and features.gutters.rainTrap
        ctx.beginPath()
        ctx.rect(x - outset / 2, 0, gw + outset, top)
        ctx.moveTo(x - outset / 2, top)
        ctx.lineTo(x + gw + outset / 2, top)
        ctx.lineTo(x + gw, top + bottom)
        ctx.lineTo(x, top + bottom)
        ctx.closePath()
        ctx.fill()
        ctx.stroke()

      ctx.beginPath()

      if floor is 0 and features.gutters.rainTrap
        ctx.moveTo(x + gw + outset / 2, 0)
        ctx.lineTo(x + gw + outset / 2, top)
        ctx.lineTo(x + gw, top + bottom)
      else
        ctx.moveTo(x + gw, 0)

      ctx.lineTo(x + gw, gh)
      ctx.globalAlpha = 0.25
      ctx.lineWidth = bh * 1.5
      ctx.stroke()
      ctx.globalAlpha = 1
      ctx.lineWidth = bh / 2
      ctx.stroke()

      ctx.beginPath()
      ctx.rect(x - 4, bh * features.gutters.y, gw + 8, features.gutters.h * 4)
      ctx.fill()
      ctx.stroke()

      if floor is features.floors.amount - 1
        ctx.beginPath()
        ctx.fillStyle = "#000"
        ctx.lineWidth = bh / 3
        ctx.moveTo(x, gh - bh - 16)
        ctx.lineTo(x + gw, gh - bh - 16)
        ctx.stroke()

        ctx.beginPath()
        ctx.rect(x, gh - bh - 4, gw, bh + 2)
        ctx.fill()

    mask = ctx.getImageData(0, 0, canvas.width, canvas.height)
    mask
