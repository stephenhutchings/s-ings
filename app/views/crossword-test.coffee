class CrosswordMakerView extends Backbone.View
  events:
    "keydown   .letter": "onKeyDown"

  template: require("templates/crossword")

  initialize: ->
    @letterEls = document.querySelectorAll(".letter input")

    if letters = localStorage.getItem "xw"
      for letter, i in letters.split(",")
        el = @letterEls.item(i)
        el.value = letter

    @toggleEmptyLetters()
    @getAcross()
    @getDown()
    @numberBoxes()

  onKeyDown: (e) ->
    e.preventDefault()

    el  = e.currentTarget.firstElementChild
    min = "A".charCodeAt(0)
    max = "Z".charCodeAt(0)
    qty = 1

    if e.keyCode is 8
      val = ""
      dir = "previous"
    else if e.keyCode is 37
      dir = "previous"
    else if e.keyCode is 38
      dir = "previous"
      qty = 25
    else if e.keyCode is 39
      dir = "next"
    else if e.keyCode is 40
      dir = "next"
      qty = 25
    else if min <= e.keyCode <= max
      val = String.fromCharCode(e.keyCode)
      dir = "next"

    if val?
      el.value = val
      @toggleEmptyLetters()

    el = el.parentNode

    if dir
      while qty > 0 and el = el[dir + "ElementSibling"]
        qty--

    el.firstElementChild.focus?()

    @saveCrossword()

  toggleEmptyLetters: ->
    arr = @letterEls
    len = arr.length

    for el, i in arr
      el.classList.toggle(
        "empty",
        not el.value and not arr.item(len - i - 1).value
      )

  saveCrossword: ->
    localStorage.setItem "xw",
      _.chain(@letterEls)
        .toArray()
        .pluck("value")
        .value()
        .join(",")

  getAcross: ->
    @across = []

    for el, i in @letterEls
      if el.value and
         (not @letterEls[i - 1]?.value or i % 25 is 0) and
         @letterEls[i + 1]?.value and
         i % 25 isnt 24
        @across.push el
        el.dataset.index = i

  getDown: ->
    @down = []

    for el, i in @letterEls
      if el.value and
         not @letterEls[i - 25]?.value and
         @letterEls[i + 25]?.value
        @down.push el
        el.dataset.index = i

  numberBoxes: ->
    clues = _.chain([@across, @down])
      .flatten()
      .uniq()
      .sort( (a, b) -> a.dataset.index - b.dataset.index )
      .each( (el, i) ->
        el.parentNode.dataset.clue = i + 1
      )
      .value()

    # console.log @across.map((el) ->
    #   value = ""
    #   parent = el.parentNode
    #   while parent.nextElementSibling and parent.firstElementChild.value
    #     value += parent.firstElementChild.value
    #     parent = parent.nextElementSibling

    #   "#{el.parentNode.dataset.clue}. (#{value.length}) #{value}"
    # ).join "\n"

    console.log @down.map((el) =>
      index = parseInt el.dataset.index
      value = ""

      while (input = @letterEls[index]) and input.value
        index += 25
        value += input.value

      "#{el.parentNode.dataset.clue}. (#{value.length}) #{value}"
    ).join "\n"



module.exports = CrosswordMakerView

