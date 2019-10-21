cache = {}

# byValue = (a, b) ->
#   av = a.reduce ((m, e, i) -> m + e * offsets[i]), 0
#   bv = b.reduce ((m, e, i) -> m + e * offsets[i]), 0
#   av - bv


# scale = [360, 1, 255]

# do buildCache = ->
#   order = _.sortBy(colors.map((e) -> color.rgb2hsv(e...)), "v")
#   console.log order
#   cache = {h: [], s: [], v: []}

#   # for key, k in ["h", "s", "v"]
#   #   s = scale[k]

#   for b, i in order.slice(1)
#     a = order[i]
#     b = b

#     min = Math.floor(a.v)
#     max = Math.floor(b.v)
#     dif = max - min

#     a.h ?= b.h or 0
#     b.h ?= a.h or 0

#     if min > 0 and i is 0
#       for j in [0..min]
#         cache.h[j] = a.h
#         cache.s[j] = a.s
#         cache.v[j] = min

#     for j in [0..dif]
#       time = if dif is 0 then 0 else ramp(j / dif)
#       time = Math.min(Math.max(time, 0), 1)
#       idx = min + j
#       cache.v[idx] = min + time * dif
#       cache.h[idx] = a.h + time * (b.h - a.h)
#       cache.s[idx] = a.s + time * (b.s - a.s)

#     if max < 256 and i is order.length - 2
#       for j in [max..255]
#         cache.h[j] = b.h
#         cache.s[j] = b.s
#         cache.v[j] = max

#   console.log cache

# process = (r, g, b, a) ->
#   {h, s, v} = color.rgb2hsv(r,g,b)
#   {r, g, b} = color.hsv2rgb(
#     cache.h[Math.floor(v)]
#     cache.s[Math.floor(v)]
#     cache.v[Math.floor(v)]
#   )
#   [~~r, ~~g, ~~b, a]
