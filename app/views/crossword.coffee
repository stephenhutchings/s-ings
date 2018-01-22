ScoreModel = require("models/score")
prefix     = require("lib/prefix")
clues      = _.shuffle require("data/clues")

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
    "keydown  .crossword-input": "onKeyUp"
    "keyup    .crossword-input": "preventDefault"
    "change   .crossword-input": "preventDefault"

  template: require("templates/crossword")

  initialize: ->
    @mode  = "cryptic"
    @score = new ScoreModel("crossword")
    @listenTo @score, "change", @onScoreChange
    @render(true)

  prepare: ->
    @undelegateEvents()
    @$el.addClass("success")
    _.delay _.bind(@render, this), 600

  render: (initial) ->
    clue = clues.pop()
    clues.unshift(clue)

    idxs = _.range(clue.word.length)

    @$el.html @template
      clue: clue
      mode: @mode
      show: _.sample(idxs, _.random(1, clue.word.length / 3))
      score: @score.display()
      length: clue.word
        .replace(/([A-Z]+)/g, (w) -> w.length)
        .replace(/\s/g, ", ")

    @$(".crossword-letter").each (i, el) ->
      el.style[prefix "transition-delay"] = "#{i * 30}ms"
      el.offsetLeft

    @delegateEvents()
    @score.timestamp = (new Date()).getTime()
    @score.pointsAvailable = if @mode is "cryptic" then 3000 else 1000
    @score.bonusAvailable  = 1000

    @$el.removeClass("success")
    @$(".crossword-input").not("[disabled]").first().focus() unless initial

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

  onKeyUp: (e) ->
    return if e.metaKey or e.ctrlKey

    e.preventDefault()

    min = "A".charCodeAt(0)
    max = "Z".charCodeAt(0)

    if e.keyCode is 8
      val = ""
      dir = "prev"
    else if e.keyCode is 37 or e.keyCode is 9 and e.shiftKey
      dir = "prev"
    else if _.include [9, 39], e.keyCode
      dir = "next"
    else if min <= e.keyCode <= max
      val = String.fromCharCode(e.keyCode)
      dir = "next"

    $prev = @$(e.target)
    $next = $prev

    $prev.val(val).prev().html(val) if val?

    while dir and ($next is $prev or $next.is("[disabled]"))
      $next = $next.parent()[dir]().find(".crossword-input")
      $next.focus()

    @checkAnswer()

  onHint: ->
    el = _.sample(@$(".crossword-input")
      .not(".disabled")
      .filter((i, el) -> not el.value)
      .toArray()
    )

    $el = $(el)
    index = $el.parent().index()
    val = clues[0].word[index]

    $el.val(val)
      .prev().html(val)
      .parent().addClass("disabled")

    $el.attr("disabled", true)

    @score.setBy {score: -500}, silent: true
    @score.pointsAvailable = ~~Math.max(@score.pointsAvailable * 0.6 - 200, 0)
    @score.bonusAvailable  = 0
    @score.trigger "tally", {ms: 300, tallyAll: true, callback: => @checkAnswer(true)}

  onScoreChange: ({changed}) ->
    { total } = changed

    if total?
      @$(".crossword-score")
        .html(@score.display().total)

  checkAnswer: (fromHint) ->
    answer = @$(".crossword-input").map((i, el) -> el.value).toArray().join("")

    if clues[0].word.match(/[A-Z]/g).join("") is answer
      total = @score.get "total"
      bonus = Math.max(10000 + @score.timestamp - (new Date()).getTime(), 0)

      if fromHint
        @prepare()
      else
        @score.setBy
          score: @score.pointsAvailable
          bonus: Math.min(~~(bonus / 10), @score.bonusAvailable)
        , silent: true

        @score.trigger "tally", {ms: 800, tallyAll: true, callback: => @prepare()}


module.exports = CrosswordView

