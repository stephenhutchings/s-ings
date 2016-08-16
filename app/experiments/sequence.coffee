timeout  = null

sequence = (arr, i = 0) ->
  name = "Process #{i + 1} of #{arr.length + i}"

  console.time "Total" if i is 0

  console.time name
  res = arr.shift()?()

  done = ->
    console.timeEnd name

    window.setTimeout (->
      if arr.length
        sequence(arr, ++i)
      else
        console.timeEnd "Total"
    ), 10

  if res?.constructor?.name is "Promise"
    res.then(done)
  else
    done()



module.exports = sequence
