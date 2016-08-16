module.exports = (ctx, r, dir = 1, size) ->
  x = size / 2 + (-.5 + Math.random()) * 8;
  y = size / 2 + (-.5 + Math.random()) * 8;

  r1 = r * (1 + Math.random() * 0.2)
  r2 = r * (1 - Math.random() * 0.3)

  variance = Math.abs(r2 / r1)
  variance = Math.min(variance, 1 / variance)

  if (variance < 0.2)
    r1 = r2
    ctx.arc(size / 2, size / 2, Math.abs(r1), 0, Math.PI * 2, dir < 0)

  else
    points = Math.floor(Math.random() * 12) + 8

    for i in [0..points]
      angle  = i * 2 * Math.PI / points * dir - Math.PI / 2
      r = if i % 2 is 0 then r1 else r2

      ctx[if i is 0 then "moveTo" else "lineTo"](
        x + r * Math.cos(angle)
        y + r * Math.sin(angle)
      )
