ScoreModel = require("models/score")
prefix     = require("lib/prefix")
keycode    = require("lib/keycode")
clues      = []

class CrosswordView extends Backbone.View
  events:
    "iostap    .crossword-mode": "setMode"
    "click     .crossword-mode": "preventDefault"
    "click     .crossword-mask": "preventDefault"
    "click     .crossword-hint": "preventDefault"
    "iostap    .crossword-hint": "onHint"
    "iostap   .crossword-input": "onSelect"
    "focusout .crossword-input": "onBlur"
    "focusin  .crossword-input": "onFocus"
    "keydown  .crossword-input": "onKeyPress"
    "keyup    .crossword-input": "preventDefault"
    "change   .crossword-input": "preventDefault"

  template: require("templates/crossword")

  initialize: ->
    @mode  = "cryptic"
    @score = new ScoreModel("crossword")
    @listenTo @score, "change", @onScoreChange
    @prepare(true)

  onComplete: ->
    @$el.addClass("success")
    _.delay _.bind(@prepare, this), 600

  prepare: (isInitial) ->
    @nextClue()
    @render()
    @delegateEvents()
    @prepareScore()
    @focus() unless isInitial

  # Cycle through the clues, and reshuffle when we run out
  nextClue: ->
    clues = clues.slice(1)
    clues = _.shuffle(require("data/clues")) if clues.length is 0

  render: (clue) ->
    clue = clues[0]
    idxs = _.range(clue.word.length)

    # Render the crossword using the crossword.pug template,
    # passing the relevant local data
    @$el.html @template
      clue: clue
      mode: @mode
      show: _.sample(idxs, _.random(1, clue.word.length / 3))
      score: @score.display()
      length: clue.word
        .replace(/([A-Z]+)/g, (w) -> w.length)
        .replace(/\s/g, ", ")

    # Now that they are rendered, add a delay on each letter,
    # cache the key elements that we'll manipulate and remove
    # the success class from the last round
    @$(".crossword-letter").each (i, el) ->
      el.style[prefix "transition-delay"] = "#{i * 30}ms"
      el.offsetLeft

    @$inputs = @$(".crossword-input")
    @$score  = @$(".crossword-score")

    @$el.removeClass("success")

  prepareScore: ->
    @score.set
      complete: false
      timestamp: (new Date()).getTime()
      pointsAvailable: if @mode is "cryptic" then 3000 else 1000
      bonusAvailable: 1000

  focus: ->
    @$inputs.not("[disabled]").first().focus()

  setMode: (e) ->
    @mode = @$(e.target).data("mode")
    @prepare()

  onSelect: (e) ->
    @$(e.target)
      .siblings("input")
      .focus()

  onFocus: (e) ->
    @$(e.target)
      .parent()
      .addClass("focus")
      .siblings()
      .removeClass("focus")

  onBlur: (e) ->
    if e.isSimulated
      e.preventDefault()
      $el = @$(e.target)
      $el.parent().removeClass("focus")

  preventDefault: (e) ->
    e.preventDefault()

  onKeyPress: (e) ->
    e.preventDefault()
    e.stopImmediatePropagation()

    key = keycode(e)

    # Depending on which key was pressed, choose which direction
    # to move in and which value to set on the current input
    switch key
      when "DELETE"
        val = ""
        dir = "prev"
      when "LEFT", "SHIFT_TAB"
        dir = "prev"
      when "RIGHT", "TAB"
        dir = "next"
      else
        if key.match("CHAR")
          val = String.fromCharCode(e.keyCode)
          dir = "next"

    $prev = @$(e.target)
    $next = $prev

    # If there is a value to set, set it on the input and the
    # adjacent element
    if val?
      $prev.val(val).prev().html(val)

    # Depending on which direction we're going, find the next
    # available input and focus that element
    if dir?
      while $next is $prev or $next.is("[disabled]")
        $next = $next.parent()[dir]().find(".crossword-input")
        $next.focus()

      @checkAnswer()

  onHint: ->
    el = _.sample(@$inputs
      .not(".disabled")
      .filter((i, el) -> not el.value)
      .toArray()
    )

    $el   = $(el)
    index = $el.parent().index()
    val   = clues[0].word[index]
    avail = @score.get("pointsAvailable")

    $el.val(val)
      .prev().html(val)
      .parent().addClass("disabled")

    $el.attr("disabled", true)

    # When you use a hint, you lose 500 points and reduce the potential
    # points you could have earned for this word. You also lose any
    # chance of earning a bonus for speed.
    @score
      .setBy(
        { score: -500 }, silent: true
      ).set(
        pointsAvailable: Math.floor(Math.max(avail * 0.6 - 200, 0))
        bonusAvailable: 0
      ).trigger("tally",
        ms: 300
        tallyAll: true
        callback: => @checkAnswer(true)
      )

  onScoreChange: ({ changed }) ->
    if changed.total?
      @$score.html(@score.display().total)

  checkAnswer: (fromHint) ->
    answer = clues[0].word.match(/[A-Z]/g).join("")
    input  = @$inputs.map((i, el) -> el.value).toArray().join("")

    if input is answer
      # Now that the game is over, ignore any events until
      # we are ready to play again
      @undelegateEvents()

      # If the user just used hints to finish the word, they don't
      # earn any points and we can just set the next game up
      if fromHint
        @onComplete()
      else
        # Compute how many points will be awarded depending on the
        # speed of the user. 10,000 points is the max bonus, but
        # that decays linearly over 10 seconds
        delta = @score.get("timestamp") - (new Date()).getTime()
        total = @score.get "total"
        avail = @score.get "bonusAvailable"
        bonus = Math.max(10000 + delta, 0)

        @score
          .set(complete: true)
          .setBy(
            score: @score.get("pointsAvailable")
            bonus: Math.min(Math.floor(bonus / 10), avail)
          , silent: true
          ).trigger("tally",
            ms: 800
            tallyAll: true
            callback: => @onComplete()
          )


module.exports = CrosswordView
