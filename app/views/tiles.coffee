app = require("app")

klass    = ".tile-link"
muted    = "tile-muted"
active   = "tile-active"
action   = "tile-actionable"
disabled = "tile-disabled"

class TilesView extends Backbone.View
  initialize: ->
    @$(".tile-img-reveal").each (i, el) ->
      el.src = $(el).data("src")

  events: ->
    isTouch = "ontouchstart" of window
    events  =
      "iostap .tile-tag-link": "filterByTag"

    if isTouch
      events["iostap"] = "activate"
    else
      events["mouseleave .tile-link"] = "deactivate"
      events["mouseenter .tile-link"] = "activate"

    return events

  activate: (e) ->

    if @$(e.target).is(".tile-close")
      e.stopImmediatePropagation()
      @deactivate()
      return

    $link = @$(e.target).closest(klass)

    if $link.size() > 0
      if e.type is "iostap" and $link.hasClass(active)
        return true
      else
        e.stopImmediatePropagation()
        done = ->
          $link
            .removeClass(muted)
            .addClass(active)
            .toggleClass(action, e.type is "iostap")
            .siblings()
            .addClass(muted)
            .removeClass(active)
            .removeClass(action)

        if e.type is "iostap"
          $("body").scrollTo($link.offset().top - 40, done)
        else
          done()

    else
      e.stopImmediatePropagation()
      @deactivate()

  deactivate: (e) ->
    @$(klass)
      .removeClass([muted, active, action].join(" "))

  filterByTag: (e) ->
    e.preventDefault()
    e.stopImmediatePropagation()

    tag = e.currentTarget.hash.slice(1)
    $el = @$(e.currentTarget).parents(".tile-tag")
    $el
      .toggleClass("active")
      .siblings()
      .removeClass("active")

    if $el.hasClass("active")
      @$(klass).each (i, el) ->
        $el = $(el)
        $el.toggleClass disabled, not $el.data("tags").match(tag)
    else
      @$(klass).removeClass(disabled)

  preventDefault: ->
    return false

module.exports = TilesView
