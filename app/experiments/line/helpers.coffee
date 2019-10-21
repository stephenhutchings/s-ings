###
 (c) 2013, Vladimir Agafonkin
 Simplify.js, a high-performance JS polyline simplification library
 mourner.github.io/simplify-js/
###

getSqDist = (p1, p2) ->
  dx = p1.x - (p2.x)
  dy = p1.y - (p2.y)
  dx * dx + dy * dy

getSqSegDist = (p, p1, p2) ->
  x = p1.x
  y = p1.y
  dx = p2.x - x
  dy = p2.y - y

  if dx isnt 0 or dy isnt 0
    t = ((p.x - x) * dx + (p.y - y) * dy) / (dx * dx + dy * dy)
    if t > 1
      x = p2.x
      y = p2.y
    else if t > 0
      x += dx * t
      y += dy * t

  dx = p.x - x
  dy = p.y - y
  dx * dx + dy * dy

simplifyRadialDist = (points, sqTolerance) ->
  prevPoint = points[0]
  newPoints = [prevPoint]

  for point in points.slice(1)
    if getSqDist(point, prevPoint) > sqTolerance
      newPoints.push point
      prevPoint = point

  newPoints.push point if prevPoint isnt point

  newPoints

simplifyDPStep = (points, first, last, sqTolerance, simplified) ->
  maxSqDist = sqTolerance

  for i in [first + 1...last]
    sqDist = getSqSegDist(points[i], points[first], points[last])
    if sqDist > maxSqDist
      index = i
      maxSqDist = sqDist

  if maxSqDist > sqTolerance
    if index - first > 1
      simplifyDPStep points, first, index, sqTolerance, simplified

    simplified.push points[index]

    if last - index > 1
      simplifyDPStep points, index, last, sqTolerance, simplified

simplifyDouglasPeucker = (points, sqTolerance) ->
  last = points.length - 1
  simp = points.slice(0, 1)
  simplifyDPStep points, 0, last, sqTolerance, simp
  simp.push points[last]
  simp

simplify = (points, tolerance = 1, highQuality) ->
  if points.length <= 2
    return points
  else
    sqTol  = Math.pow(tolerance, 2)
    points = if highQuality then points else simplifyRadialDist(points, sqTol)
    return simplifyDouglasPeucker(points, sqTol)


module.exports =
  simplify: simplify
  distance: getSqDist

  arrayify: (pts) -> ([x, y] for { x, y } in pts)

  objectify: (pts) -> ({ x, y } for [x, y] in pts)

  # Find the intersection between two line segments
  intersection: (x1, y1, x2, y2, x3, y3, x4, y4) ->
    # Check if none of the lines are of length 0
    if (x1 is x2 and y1 is y2) or (x3 is x4 and y3 is y4)
      return false

    denominator = (y4 - y3) * (x2 - x1) - (x4 - x3) * (y2 - y1)

    # are the lines are parallel?
    if denominator is 0
      return false

    ua = ((x4 - x3) * (y1 - y3) - (y4 - y3) * (x1 - x3)) / denominator
    ub = ((x2 - x1) * (y1 - y3) - (y2 - y1) * (x1 - x3)) / denominator

    # is the intersection along the segments?
    if ua < 0 or ua > 1 or ub < 0 or ub > 1
      return false

    # Return an object with x and y coordinates of the intersection
    x = x1 + ua * (x2 - x1)
    y = y1 + ua * (y2 - y1)

    return { x, y }

  # Convert a line into a Catmull-Rom spline
  spline: (points, divisions = 32) ->
    points = [].concat(points)
    spline = points.slice 0, 1

    while points.length > 3
      p1x = 1 * points[3].x - 3 * points[2].x + 3 * points[1].x - points[0].x
      p1y = 1 * points[3].y - 3 * points[2].y + 3 * points[1].y - points[0].y
      p2x = 2 * points[0].x - 5 * points[1].x + 4 * points[2].x - points[3].x
      p2y = 2 * points[0].y - 5 * points[1].y + 4 * points[2].y - points[3].y

      st1 = 1.0 / divisions
      st2 = st1 * st1
      st3 = st1 * st2

      d1x = 0.5 * (st3 * p1x + st2 * p2x + st1 * (points[2].x - points[0].x))
      d1y = 0.5 * (st3 * p1y + st2 * p2y + st1 * (points[2].y - points[0].y))
      d2x = 3.0 * st3 * p1x + st2 * p2x
      d2y = 3.0 * st3 * p1y + st2 * p2y
      d3x = 3.0 * st3 * p1x
      d3y = 3.0 * st3 * p1y

      px = points[1].x
      py = points[1].y

      for j in [0...divisions]
        px  += d1x
        py  += d1y
        d1x += d2x
        d1y += d2y
        d2x += d3x
        d2y += d3y

        spline.push x: px, y: py

      points.shift()

    return spline

  catmullRomBezier: (data, alpha) ->
    if alpha is 0 or alpha is undefined
      false
    else
      d = Math.round(data[0].x) + ',' + Math.round(data[0].y) + ' '
      length = data.length
      i = 0
      while i < length - 1
        p0 = if i is 0 then data[0] else data[i - 1]
        p1 = data[i]
        p2 = data[i + 1]
        p3 = if i + 2 < length then data[i + 2] else p2

        d1 = Math.sqrt(Math.pow(p0.x - p1.x, 2) + Math.pow(p0.y - p1.y, 2))
        d2 = Math.sqrt(Math.pow(p1.x - p2.x, 2) + Math.pow(p1.y - p2.y, 2))
        d3 = Math.sqrt(Math.pow(p2.x - p3.x, 2) + Math.pow(p2.y - p3.y, 2))

        d3powA  = Math.pow d3, alpha
        d3pow2A = Math.pow d3, (2 * alpha)
        d2powA  = Math.pow d2, alpha
        d2pow2A = Math.pow d2, (2 * alpha)
        d1powA  = Math.pow d1, alpha
        d1pow2A = Math.pow d1, (2 * alpha)

        A = 2 * d1pow2A + 3 * d1powA * d2powA + d2pow2A
        B = 2 * d3pow2A + 3 * d3powA * d2powA + d2pow2A
        N = 3 * d1powA * (d1powA + d2powA)
        M = 3 * d3powA * (d3powA + d2powA)

        if N > 0
          N = 1 / N

        if M > 0
          M = 1 / M

        bp1 =
          x: (-d2pow2A * p0.x + A * p1.x + d1pow2A * p2.x) * N
          y: (-d2pow2A * p0.y + A * p1.y + d1pow2A * p2.y) * N

        bp2 =
          x: (d3pow2A * p1.x + B * p2.x - (d2pow2A * p3.x)) * M
          y: (d3pow2A * p1.y + B * p2.y - (d2pow2A * p3.y)) * M

        if bp1.x is 0 and bp1.y is 0
          bp1 = p1

        if bp2.x is 0 and bp2.y is 0
          bp2 = p2

        d += 'C' + bp1.x + ',' + bp1.y + ' ' + bp2.x + ',' + bp2.y + ' ' + p2.x + ',' + p2.y + ' '
        i++
      d

  # Sort all points by distance to a point
  nearest: (points, point) ->
    points.sort((a, b) ->
      da = Math.sqrt Math.pow(a.x - point.x, 2) + Math.pow(a.y - point.y, 2)
      db = Math.sqrt Math.pow(b.x - point.x, 2) + Math.pow(b.y - point.y, 2)
      da - db
    )

  # Interpolate all the mid points between the points to an even distance
  interpolate: (points, div = 1) ->
    _.flatten(
      for p0, i in points.slice(0, -1)
        p1 = points[i + 1]
        dx = p1.x - p0.x
        dy = p1.y - p0.y
        dist = Math.sqrt((dx * dx) + (dy * dy)) * div

        for i in [0..dist]
          t = i / dist

          x: p0.x + dx * t
          y: p0.y + dy * t
    )

  makeGrid: (width, height, div) ->
    rows = Math.floor(height / div)
    cols = Math.floor(width / div)

    xOffset = (width  - cols * div) / 2
    yOffset = (height - rows * div) / 2

    _.flatten(
      for y in [0..rows]
        for x in [0..cols]
          x: xOffset + x * div
          y: yOffset + y * div
    )


