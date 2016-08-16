module.exports = (ctx, canvas, scale, done) ->
  if scale < 1
    image = new Image()
    image.onload = ->
      canvas.height /= scale
      canvas.width  /= scale
      ctx.drawImage(this, 0, 0, canvas.width, canvas.height)
      done?()

    image.src = canvas.toDataURL()

  else
    W  = canvas.width
    H  = canvas.height
    W2 = Math.round(W / scale)
    H2 = Math.round(H / scale)
    img = ctx.getImageData(0, 0, W, H)
    img2 = ctx.getImageData(0, 0, W2, H2)
    data = img.data
    data2 = img2.data
    ratioW = W / W2
    ratioH = H / H2
    ratioWHalf = Math.ceil(ratioW/2)
    ratioHHalf = Math.ceil(ratioH/2)

    for j in [0...H2]
      for i in [0...W2]
        x2 = (i + j * W2) * 4
        weight = 0
        weights = 0
        weightsAlpha = 0
        gxR = gxG = gxB = gxA = 0
        centerY = (j + 0.5) * ratioH

        yy = Math.floor(j * ratioH)
        while yy < (j + 1) * ratioH
          dy = Math.abs(centerY - (yy + 0.5)) / ratioHHalf
          centerX = (i + 0.5) * ratioW
          w0 = dy * dy

          xx = Math.floor(i * ratioW)
          while xx < (i + 1) * ratioW
            dx = Math.abs(centerX - (xx + 0.5)) / ratioWHalf
            w = Math.sqrt(w0 + dx * dx)

            if w >= -1 and w <= 1
              weight = 2 * w * w * w - (3 * w * w) + 1
              if weight > 0
                dx = 4 * (xx + yy * W)

                gxA += weight * data[dx + 3]
                weightsAlpha += weight

                if data[dx + 3] < 255
                  weight = weight * data[dx + 3] / 250
                gxR += weight * data[dx]
                gxG += weight * data[dx + 1]
                gxB += weight * data[dx + 2]
                weights += weight
            xx++
          yy++

        data2[x2]     = gxR / weights
        data2[x2 + 1] = gxG / weights
        data2[x2 + 2] = gxB / weights
        data2[x2 + 3] = gxA / weightsAlpha

    ctx.clearRect(0, 0, Math.max(W, W2), Math.max(H, H2))
    ctx.putImageData(img2, 0, 0)

    done?()
