module.exports =
  signature: "The Computer"
  inventory: ["compliments"]

  phrasings: [
    (compliment, a) -> compliment
  ]

  thesaurus: require("./data/thecomputer")
