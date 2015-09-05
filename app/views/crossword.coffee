ScoreModel = require("models/score")
prefix     = require("lib/prefix")
clues      = _.shuffle require("data/clues")

class CrosswordView extends Backbone.View
  events:
    "iostap   .crossword-mode": "setMode"
    "click    .crossword-mode": "setMode"
    "iostap  .crossword-input": "focus"
    "click   .crossword-input": "focus"
    "focus   .crossword-input": "focus"
    "blur    .crossword-input": "blur"
    "keydown .crossword-input": "onKeyUp"
    "keyup   .crossword-input": "preventDefault"
    "change  .crossword-input": "preventDefault"

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

    @$el.removeClass("success")
    @$(".crossword-input").not("[disabled]").first().focus() unless initial

  setMode: (e) ->
    @mode = @$(e.target).data("mode")
    @prepare()

  focus: (e) ->
    $el = @$(e.target)
    $el.focus() unless e.type is "focusin"
    $el.parent().addClass("focus").siblings().removeClass("focus")

  blur: (e) ->
    $el = @$(e.target)
    $el.parent().removeClass("focus")

  preventDefault: (e) ->
    e.preventDefault()
    false

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

    return not (dir and val)

  onScoreChange: ({changed}) ->
    { total } = changed

    if total?
      @$(".crossword-score")
        .html(@score.display().total)

  checkAnswer: ->
    answer = @$(".crossword-input").map((i, el) -> el.value).toArray().join("")

    if clues[0].word.replace("-", "") is answer
      total = @score.get "total"
      bonus = Math.max(10000 + @score.timestamp - (new Date()).getTime(), 0)

      @score.setBy
        score: if @mode is "cryptic" then 3000 else 1000
        bonus: ~~(bonus / 10)
      , silent: true

      @score.trigger "tally", {tallyFrom: total, ms: 300, tallyAll: true}
      @prepare()


module.exports = CrosswordView

