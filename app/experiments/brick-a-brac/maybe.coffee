module.exports = (chance = 0.5) ->
  Math.random() > (1 - chance)
