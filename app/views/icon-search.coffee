timeouts = {}

class IconSearchView extends Backbone.View
  events:
    "mouseenter .icon": "onEnter"
    "mouseout   .icon": "onLeave"
    "focusin    #icon-search": "onFocus"
    "focusout   #icon-search": "onBlur"
    "input      #icon-search": "onChange"

  initialize: (@options) ->
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

      $el.addClass("active-before")

      before = =>
        @$el.addClass("hover")
        $el.addClass("transition")

      after = =>
        $el.addClass("active")

        @$details.html """
          <i class="#{@options.classname} #{data.class}"></i>
          <strong class="icon-name">#{data.name}</strong>
          <code class="bg-hl icon-class">.#{data.class}</code>
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
      $el.removeClass("active")

      window.clearTimeout timeouts[data.name]
      timeouts[data.name] = window.setTimeout ->
        $el.removeClass("active-before transition")
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
        $(el).data("match").match(new RegExp(val, "i"))

      max    = 4
      list   = _.map(@$active.toArray(), (el) -> $(el).data("class"))
      list   = list.map((e) -> "<code class='icon-class'>#{e}</code>")
      total  = Math.min(list.length, max)

      @$details.html ->
        if list.length is 1
          list[0]
        else if list.length > 0
          """
          #{list.slice(0, total - 1).join(", ")} and #{
            if list.length > total
              (r = list.length - total + 1) + " other" + (if r isnt 1 then "s" else "")
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


module.exports = IconSearchView

