###
  Paints img2's pixels over the top of img1
  `toDataURL` borks node/jsdom when working with a very large canvas
  but Safari only likes to do it the easy way
###

module.exports = (ctx1, data, x = 0, y = 0) ->
  ctx2 = document.createElement("canvas").getContext("2d")

  if window.navigator?.userAgent?.match(/Node.js/)
    ctx2.canvas.height = ctx1.canvas.height
    ctx2.canvas.width  = ctx1.canvas.width

    ctx2.putImageData(data, x, y)

    img1 = ctx1.getImageData(0, 0, ctx1.canvas.width, ctx1.canvas.height)
    img2 = ctx2.getImageData(0, 0, ctx1.canvas.width, ctx1.canvas.height)
    rgb = []

    for a1, i in img1.data
      if rgb.length < 3
        rgb.push a1
      else
        if (a2 = img2.data[i]) > 0
          [r2, g2, b2] = img2.data.slice(i - 3, i)
          [r1, g1, b1] = rgb

          r2 = r1 + (r2 - r1) * (a2 / 255)
          g2 = g1 + (g2 - g1) * (a2 / 255)
          b2 = b1 + (b2 - b1) * (a2 / 255)

          img1.data[i - 3] = Math.min(r2, 255)
          img1.data[i - 2] = Math.min(g2, 255)
          img1.data[i - 1] = Math.min(b2, 255)
          img1.data[i - 0] = Math.min(a1 + a2, 255)

        rgb = []

    ctx1.putImageData(img1, 0, 0)

  else
    image = new Image()

    ctx2.canvas.height = data.height
    ctx2.canvas.width  = data.width
    ctx2.putImageData(data, 0, 0)

    new Promise (resove, reject) ->
      image.onload = ->
        ctx1.drawImage(this, x, y)
        resove(this)

      image.src = ctx2.canvas.toDataURL()
