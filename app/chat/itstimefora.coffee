module.exports =
  signature: "Periphrastic SuggestionBot"
  inventory: ["time", "traits", "matching"]
  phrasings: [
    (time, trait, matching, a) ->
      "It’s #{time}. Time for #{a(trait)} #{matching(trait)}?"

    (time, trait, matching, a) ->
      """
        If it’s already #{time} it’s
         #{[trait, matching(trait)].join(" ").replace(/\s/g, "-")}
         time!
      """

    (time, trait, matching, a) ->
      "If it’s #{time} it’s time for #{a(trait)} #{matching(trait)}, maybe. "

    (time, trait, matching, a) ->
      "#{time}. Too early for #{a(trait)} #{matching(trait)}?"

    (time, trait, matching, a) ->
      "Everybody needs #{a(trait)} #{matching(trait)} at #{time}..."
  ]

  thesaurus: _.extend require("./data/itstimefora"),
    time: -> moment().format("h:mm a")
    matching: ->
      (trait) =>
        matches = /^[a-z]h*/
        anthing = Math.random() > 0.9
        samples = _.filter(@things, (t) ->
          t.match(matches)?[0] is trait.match(matches)?[0] or anthing
        )

        _.sample((samples.length and samples) or @things)
