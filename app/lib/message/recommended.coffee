module.exports =
  signature: "S&middot;INGS Recommendation Engine&reg;"
  inventory: ["things", "get", "after"]

  phrasings: [
    (its, get, post, a) ->
      "Let me recommend a #{get(its).type} called #{get(its).name}. #{post}"

    (its, get, post, a) ->
      "What do you think of the #{get(its).type} #{get(its).name}? #{post}"

    (its, get, post, a) ->
      "Have you heard of #{get(its).name}? I love that #{get(its).type}."

    (its, get, post, a) ->
      "You know, I really dig this #{get(its).type} called #{get(its).name}."

    (its, get, post, a) ->
      "Do you like #{get(its).name}? Because I do."

  ]

  thesaurus: _.extend require("data/recommended"),
    get: ->
      (things) ->
        type: _.chain(things).keys().first().value()
        name: _.chain(things).values().first().sample().value()
