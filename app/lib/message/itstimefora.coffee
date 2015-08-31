module.exports =
  signature: "Periphrastic SuggestionBot"
  inventory: ["time", "traits", "things"]
  phrasings: [
    (time, trait, thing, a) ->
      "It’s #{time}. Time for #{a(trait)} #{thing}?"

    (time, trait, thing, a) ->
      """
        If it’s already #{time} it’s
         #{[trait, thing].join(" ").replace(/\s/g, "-")}
         time!
      """
  ]

  thesaurus: _.extend require("data/itstimefora"),
    time: -> moment().format("h:mm a")
