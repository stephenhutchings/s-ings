module.exports = (img, r = 255, g = 255, b = 255, invert = false) ->
  i = 0
  while i < img.data.length
    alpha = (img.data[i] + img.data[i + 1] + img.data[i + 2]) / 3
    img.data[i    ] = r
    img.data[i + 1] = g
    img.data[i + 2] = b
    img.data[i + 3] = if invert then 255 - alpha else alpha

    i += 4
