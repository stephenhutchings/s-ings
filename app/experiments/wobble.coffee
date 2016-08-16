module.exports = (number, amount, limit) ->
  if arguments.length is 1
    amount = number
    number = 0

  number = number - amount / 2 + Math.random() * amount
  number = Math.min(Math.max(number, -limit), limit) if limit?
  number
