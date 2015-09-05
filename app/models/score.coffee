Easie = require("lib/easie")

class ScoreModel extends Backbone.Model
  defaults:
    turns: 0

  initialize: (@id) ->
    @resetScore(+window.localStorage.getItem("s-ings.game.#{@id}") or 0)

    @on "reset", @resetScore, this
    @on "tally", @tallyScore, this
    @on "change", @getTotal, this

  resetScore: (record) ->
    window.clearTimeout @timeout

    @set
      score: 0
      record: record
      bonus: 0
      total: 0
      correct: 0
      incorrect: 0
      consecutive: 0
      lastBonus: 0
      lastScore: 0

  display: ->
    display = {}

    for key, val of @attributes
      display[key] = val.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",")

    return display

  # Once the game has ended, "tally up" the scores into the combined score.
  tallyScore: ({callback, ms, tallyFrom, tallyAll}) ->
    window.clearTimeout @timeout

    { bonus, score, record, total } = @attributes

    if score is 0
      callback?()
    else
      start   = Date.now()
      ms      = Math.min((ms or 3000), score)
      fps     = 1000 / 60
      frame   = 0
      frames  = ms / fps
      initial = if tallyFrom then tallyFrom else 0

      @inProgress = true

      do repeat = =>
        dist = (frame / frames) or 0
        dist = 1 unless 0 <= dist <= 1

        attrs =
          total: Math.round(
            Easie.quartInOut(dist, initial, (bonus + score - initial), 1)
          )

        attrs.record = Math.max(attrs.total, record or 0)

        if tallyAll
          attrs.bonus = Math.round(Easie.quartInOut(dist, initial, bonus - initial, 1))
          attrs.score = Math.round(Easie.quartInOut(dist, initial, score - initial, 1))

        @set attrs

        if frame < frames
          window.clearTimeout @timeout
          @timeout = window.setTimeout(repeat, fps)
          frame = Math.floor((Date.now() - start) / fps)
        else
          @inProgress = false
          callback?()

  # When scores change, ensure the total still represents the score + bonus
  getTotal: ({changed}) ->
    unless changed.total or @inProgress or not (changed.total and changed.bonus)
      @set total: @get("score") + @get("bonus")
    if changed.record
      window.localStorage.setItem("s-ings.game.#{@id}", changed.record)

  # Similar to set, this function allows an increase/decrease to numerical
  # attributes by an amount rather than getting and setting. Allows either
  # (key, val) or ({key, val}) syntax.
  setBy: (obj, amount) ->
    if typeof obj is "string"
      key = obj
      obj = {}
      obj[key] = amount
    else
      opts = amount

    for key, val of obj
      prev = @get(key)
      @set(key, Math.max(prev + val, 0), opts)

      if key is "lastBonus" or key is "lastScore"
        console?.log?("`lastBonus` & `lastScore` cannot be set")
        return

      if key is "bonus" and val > 0
        @set({lastBonus: 0}, silent: true)
        @set(lastBonus: val)

      if key is "score" and val > 0
        @set({lastScore: 0}, silent: true)
        @set(lastScore: val)

module.exports = ScoreModel
