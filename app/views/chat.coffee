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

  select: ->
    @random(
      [
        "itstimefora"
        "recommended"
        "thecomputer"
        "recommended"
        "itstodayand"
        "recommended"
      ]
    , "data")

  require: (path) ->
    _.extend { path }, require("chat/#{path}")

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

    # Kerner
    $k = $("<span>")
    $k.css("font-size", "10em").appendTo("body")

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

    $k.remove()
    message.join(" ")

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
    , 600

  wrapWord: (w) ->
    "<div class=\"word\">#{w}</div>"

  wrapSpan: (c, d, m) ->
    unless c is " "
      t = Prefix("transition-delay")
      t = t.replace(/([A-Z])/g, (w, c) -> "-" + c.toLowerCase())
      style = "#{t}: #{d}ms;"
      style += "margin-left: #{m}px" if m
      "<span style=\"#{style}\" class=\"char\">#{c}</span>"

  random: (from, name) ->
    from = _.without(from, @history[name]) if from.length > 1
    @history[name] = _.sample from

module.exports = MessageView
