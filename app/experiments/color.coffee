module.exports =
  rgb2hsv: (r,g,b) ->
    out = {}

    min = if   r < g then r   else g
    min = if min < b then min else b

    max = if   r > g then r   else g
    max = if max > b then max else b

    out.v = max
    delta = max - min

    if (delta < 0.00001)
      out.s = 0
      out.h = 0
      return out

    if max > 0
      out.s = (delta / max)
    else
      out.s = 0
      out.h = NaN
      return out

    if r >= max
      out.h = ( g - b ) / delta
    else if g >= max
      out.h = 2 + ( b - r ) / delta
    else
      out.h = 4 + ( r - g ) / delta

    out.h *= 60
    out.h += 360 if out.h < 0

    return out

  hsv2rgb: (h, s, v) ->
    out = {}

    if s <= 0
      out.r = v
      out.g = v
      out.b = v
      return out

    hh = h
    hh = 0 if hh >= 360
    hh /= 60
    i = Math.floor hh
    ff = hh - i
    p = v * (1 - s)
    q = v * (1 - (s * ff))
    t = v * (1 - (s * (1 - ff)))

    switch i
      when 0
        out.r = v
        out.g = t
        out.b = p
      when 1
        out.r = q
        out.g = v
        out.b = p
      when 2
        out.r = p
        out.g = v
        out.b = t
      when 3
        out.r = p
        out.g = q
        out.b = v
      when 4
        out.r = t
        out.g = p
        out.b = v
      else
        out.r = v
        out.g = p
        out.b = q

    return out
