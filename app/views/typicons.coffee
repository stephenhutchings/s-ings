timeouts = {}

class TypiconsView extends Backbone.View
  events:
    "mouseenter .icon": "onEnter"
    "mouseout   .icon": "onLeave"
    "focusin    #icon-search": "onFocus"
    "focusout   #icon-search": "onBlur"
    "input      #icon-search": "onChange"

  initialize: ->
    @$details   = @$("#icon-details")
    @$icons     = @$(".icon")
    @$search    = @$("#icon-search")
    @searchText = @$details.text()

  onEnter: (e) ->
    if e.target is e.currentTarget
      $el  = @$(e.target)
      data = $el.data()

      window.clearTimeout timeouts[data.name]
      window.clearTimeout timeouts["change"]

      $el.addClass("expand-before")

      before = =>
        @$el.addClass("hover")
        $el.addClass("transition")

      after = =>
        $el.addClass("expand")

        @$details.html """
          <i class="typcn typcn-#{data.name}"></i>
          <span class="icon-name">#{data.name}</span>
          <small class="icon-code">#{data.code}</small>
        """

      timeouts[data.name] = window.setTimeout ->
        before()
        timeouts[data.name] = window.setTimeout after, 100
      , 1

  onLeave: (e) ->
    if e.target is e.currentTarget
      $el  = @$(e.target)
      data = $el.data()
      @$el.removeClass("hover")
      $el.removeClass("expand")

      window.clearTimeout timeouts[data.name]
      timeouts[data.name] = window.setTimeout =>
        $el.removeClass("expand-before transition")
      , 300

    window.clearTimeout timeouts["change"]
    timeouts["change"] = window.setTimeout (=> @onChange()), 300

  onFocus: (e) ->
    @$el.addClass("search")

  onBlur: (e) ->
    @$el.removeClass("search")
    @$icons.removeClass("inactive")

  onChange: (e) ->
    val = @$search.val()
    @$icons.removeClass("inactive")

    if val
      @$active = @$icons.filter (i, el) ->
        $(el).data("match").match(val)

      max    = 4
      list   = _.map(@$active.toArray(), (el) -> $(el).data("name"))
      total  = Math.min(list.length, max)

      @$details.html ->
        if list.length is 1
          list[0]
        else if list.length > 0
          """
          #{list.slice(0, total - 1).join(", ")} and #{
            if list.length > total
              list.length - total + " others"
            else
              list.slice(total - 1)[0]
          }
          """
        else
          """
            No results found for “#{val}”.
            Try <b>media</b>, <b>weather</b> or <b>arrow</b>.
          """

      @$icons.not(@$active).addClass("inactive")

    else
      @$details.html(@searchText)


module.exports = TypiconsView

