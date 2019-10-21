helpers = require("experiments/line/helpers")

module.exports = (points) ->
  newOrder = [points[0]]

  while points.length > 0
    current = _.last(newOrder)
    nearest = helpers.nearest(points, current)[0]
    points  = _.without(points, nearest)
    newOrder.push(nearest)

  newOrder
