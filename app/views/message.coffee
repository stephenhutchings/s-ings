class MessageView extends Backbone.View
  events:
    "iostap": "generate"
    "click": "generate"

  initialize: ->
    @generate()

  generate: ->
    do _.bind(_.compose(@prettify, @extract, @something), this)

  something: ->
    @last =
      _.chain([
        require("lib/message/itstimefora")
        require("lib/message/recommended")
        require("lib/message/thecomputer")
        require("lib/message/itstodayand")
      ])
      .without(@last)
      .sample()
      .value()

  extract: ({phrasings, inventory, thesaurus}) ->
    func = _.sample phrasings
    args =
      for key in inventory
        switch typeof thesaurus[key]
          when "function"
            thesaurus[key]()
          when "object"
            obj = thesaurus[key]
            if _.isArray(obj) then _.sample(obj) else obj

    func args..., (t) ->
      (if t.match(/^[aeiou]/) then "an " else "a ") + t

  prettify: (string) ->
    duration = 300
    i = 0
    msg =
      for word in string.split(" ")
        @wrapWord (
          for span in word
            i++
            @wrapSpan(span, i / string.length * duration)
        ).join("")

    @$el.addClass("leave").removeClass("active")

    window.clearTimeout @timeout
    @timeout = window.setTimeout =>
      @$el.removeClass("leave")
      @$("#message-content").html(msg.join("")).offset()
      @$("#message-author").html(@last.signature)
      @$el.addClass("active")
    , duration + 300

  wrapWord: (w) ->
    "<div class=\"word\">#{w}</div> "

  wrapSpan: (c, delay) ->
    unless c is " "
      """
      <span style="
      -webkit-transition-delay: #{delay}ms;
      -moz-transition-delay: #{delay}ms;
      -ms-transition-delay: #{delay}ms;
      -o-transition-delay: #{delay}ms;
      transition-delay: #{delay}ms;
      " class="char">#{c}</span>"""
      .replace(/\s+/g, " ")


module.exports = MessageView
