timeouts = {}

class TypiconsView extends Backbone.View
  events:
    "mouseenter .icon": "onEnter"
    "mouseout   .icon": "onLeave"
    "focusin    #icon-search": "onFocus"
    "focusout   #icon-search": "onBlur"
    "input      #icon-search": "onChange"

  initialize: ->
    @searchText = @$("#icon-details").text()
    @$icons = @$(".icon")

  onEnter: (e) ->
    if e.target is e.currentTarget
      $el = @$(e.target)
      key = $el.data("name")

      @$el.addClass("hover")
      window.clearTimeout timeouts[key]

      data = @$(e.target).data()

      @$("#icon-details").html -> """
      <img class="icon-img" src="/img/projects/typicons/svg/#{data.name}.svg">
      <span class="icon-name">#{data.name}</span>
      <small class="icon-code">#{data.code}</small>
      """

      $el.addClass("expand-before")
      timeouts[key] = window.setTimeout ->
        $el.addClass("expand")
      , 1

  onLeave: (e) ->
    if e.target is e.currentTarget
      $el = @$(e.target)
      key = $el.data("name")
      @$el.removeClass("hover")
      @onChange()

      window.clearTimeout timeouts[key]
      timeouts[$el.data("name")] = window.setTimeout ->
        $el.removeClass("expand")
        timeouts[key] = window.setTimeout ->
          $el.removeClass("expand-before")
        , 300
      , 100

  onFocus: (e) ->
    @$el.addClass("search")

  onBlur: (e) ->
    @$el.removeClass("search")

    @$icons.removeClass("inactive")

  onChange: (e) ->
    val = @$("#icon-search").val()
    @$icons.removeClass("inactive")

    if val
      @$active = @$icons.filter (i, el) ->
        $(el).data("match").match(val)

      max    = 4
      list   = _.map(@$active.toArray(), (el) -> $(el).data("name"))
      total  = Math.min(list.length, max)

      @$("#icon-details").html ->
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
            No results found for "#{val}". Try "media", "weather" or "arrow".
          """

      @$icons.not(@$active).addClass("inactive")

    else
      @$("#icon-details").html(@searchText)


module.exports = TypiconsView

