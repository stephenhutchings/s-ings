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

  # Sort all points by distance to a point
  nearest: (points, point) ->
    _.sort(points, (a, b) ->
      da = Math.abs(a.x - point.x) + Math.abs(a.y - point.y)
      db = Math.abs(b.x - point.x) + Math.abs(b.y - point.y)
      b - a
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


