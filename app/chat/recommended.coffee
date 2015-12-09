module.exports =
  signature: "S&middot;INGS Recommendation Engine&reg;"
  inventory: ["things", "get", "after"]

  phrasings: [
    (its, get, post, a) ->
      "Let me recommend #{a(get(its).type)} called #{get(its, ".").name} #{post}"

    (its, get, post, a) ->
      "What do you think of the #{get(its).type} #{get(its, "?").name} #{post}"

    (its, get, post, a) ->
      "Heard of #{get(its, "?").name} I love that #{get(its).type}."

    (its, get, post, a) ->
      "You know, I really dig #{get(its, ".").name}"

    (its, get, post, a) ->
      "Check out #{a(get(its).type)} called #{get(its, ".").name}"

    (its, get, post, a) ->
      "Do you like #{get(its, "?").name} I do."

    (its, get, post, a) ->
      "I can’t say enough good things about #{get(its, ".").name}"

    (its, get, post, a) ->
      "If only every #{get(its).type} was as good as #{get(its, ".").name}"
  ]

  thesaurus: _.extend require("./data/recommended"),
    get: ->
      (things, punctuate = "") ->
        name = _.chain(things).values().first().sample().value()
        type = _.chain(things).keys().first().value()
        find = window.encodeURIComponent "#{name} #{type}"
        link =
          "<a href='http://www.google.com/?q=#{find}#'>#{name}#{punctuate}</a>"

        { type, name: link }
