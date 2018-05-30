Prefix = require("lib/prefix")

class MessageView extends Backbone.View
  events:
    "iostap": "generate"

  history: {}

  initialize: ->
    @$el.height($(window).height())
    @$content = @$("#message-content")
    @$author = @$("#message-author")
    @render(@prettify "Loading...")

    @undelegateEvents()

  ready: ->
    @render(@prettify "To start chatting, tap anywhere.")
    @delegateEvents()

  generate: (e) ->
    if @$(e?.target).closest("a").length is 0
      tasks = [@select, @require, @extract, @prettify, @render]
      do _.bind(_.compose(tasks.reverse()...), this)

  # Choose a bot to play with, giving priority to the recommender
  select: ->
    @random [
      "itstimefora"
      "recommended"
      "thecomputer"
      "recommended"
      "itstodayand"
      "recommended"
    ], "data"

  require: (path) ->
    _.extend { path }, require("chat/#{path}")

  # Using the data from any of the chat bots, choose a random phrasing and
  # pass it the relavant data from the thesaurus (the YAML file) based on
  # the data type. Use the random method to ensure there are no repeats.
  # The last argument passed to each phrase is a method to choose the correct
  # article depending on the whether the noun starts with a vowel.
  extract: ({phrasings, inventory, thesaurus, path}) ->
    says = @random phrasings, path
    args =
      for key in inventory
        switch typeof thesaurus[key]
          when "function"
            thesaurus[key]()
          when "object"
            obj = thesaurus[key]
            if _.isArray(obj)
              @random(obj, key)
            else
              obj

    says args..., (t) -> (if t.match(/^[aeiou]/) then "an " else "a ") + t

  prettify: (string) ->
    i = 0

    # Each letter is placed in a non-inline span, so the kerning will be
    # lost and needs to be re-engineered by rendering the letter pairs
    # at 10 times their normal size
    $k = $("<span>")
    $k.css("font-size", "10em").appendTo("body")

    # Split each sentence into words, and each word into spans, taking care
    # not to preserve any HTML tags that are contained within
    interval = 300 / string.replace(/(<[^<]+>)/g, "").length
    message  =
      for word in _.compact(string.split(/[\s$](<a[^<]+<\/a>)*/))
        middle = word.match(/>([^<]+)/)?[1] or word
        [start, end] = word.split(middle)
        middle =
          for word in middle.split(" ")
            @wrapWord (
              for span, j in word
                if j > 0
                  w1 = $k.html(word[j - 1] + span).width()
                  w2 = $k.html(word[j - 1]).width() + $k.html(span).width()
                  wd = (w1 - w2) / 10
                i++
                @wrapSpan(span, i * interval, wd)
            ).join("")

        [start, middle.join(" "), end].join("")

    # Remove the kerning element
    $k.remove()
    message.join(" ")

  # Animate last message out, and the new one in after 800ms
  render: (message) ->
    @$el.addClass("leave").removeClass("active")

    window.clearTimeout @timeout
    @timeout = window.setTimeout =>
      @$el.removeClass("leave")
      @$content.html(message).offset()
      @$author.html(
        if @history.data
          @require(@history.data).signature
        else
          "The Computer"
      )
      @$el.addClass("active")
    , 800

  wrapWord: (w) ->
    "<div class=\"word\">#{w}</div>"

  # Wrap a c = character in a span with transition d = delay and
  # m = margin to simulate the kerning
  wrapSpan: (c, d, m) ->
    unless c is " "
      t = Prefix("transition-delay")
      t = t.replace(/([A-Z])/g, (w, c) -> "-" + c.toLowerCase())
      style = "#{t}: #{d}ms;"
      style += "margin-left: #{m}px" if m
      "<span style=\"#{style}\" class=\"char\">#{c}</span>"

  # Try not to repeat anything by splicing the last choice out of the
  # possible options for the next item, when there's enough to choose from.
  # Duplicate options will result in possible repeats, but this is intended.
  random: (from, name) ->
    index = from.indexOf(@history[name])
    [].concat(from).splice(index, 1) if index? and from.length > 1
    item = _.sample from
    @history[name] = item


module.exports = MessageView
