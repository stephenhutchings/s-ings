timeout  = null
label = document.querySelector("label")
html  = label.innerHTML

sequence = (arr, i = 0, title = "Process", resolve) ->
  step = (resolve, reject) ->
    name = "#{title} #{i + 1} / #{arr.length + i}"

    console?.time? "#{title} Total" if i is 0
    label.innerHTML = name if title isnt "Process"

    console?.time? name
    res = arr.shift()?()

    next = ->
      console?.timeEnd? name

      window.setTimeout (->
        if arr.length
          sequence(arr, ++i, title, resolve)
        else
          console?.timeEnd? "#{title} Total"
          resolve()
      ), 1

    if res?.constructor?.name is "Promise"
      res.then(next)
    else
      next()

  if i is 0
    label.innerHTML = html if title isnt "Process"
    new Promise(step)
  else
    step(resolve)

module.exports = sequence
