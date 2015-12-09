module.exports =
  signature: "Conversational Tony"
  inventory: ["today", "time", "ergo", "after"]

  phrasings: [
    (today, time, ergo, after, a) -> "It’s #{today()} today#{after}"
    (today, time, ergo, after, a) -> "#{today()}. #{today(ergo)}"
    (today, time, ergo, after, a) ->
      "#{today()} #{time(ergo)}#{after}"
  ]

  thesaurus: _.extend require("./data/itstodayand"),
    today: ->
      (ergo) ->
        if ergo
          _.sample ergo[moment().format("dddd").toLowerCase()]
        else
          moment().format("dddd")

    time: ->
      ({ times }) ->
        h = moment().get("h") + moment().get("m") / 60
        _.sample times[Math.floor(h / 24 * (times.length - 1))]
