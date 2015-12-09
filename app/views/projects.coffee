app = require("app")

klass    = ".project-link"
muted    = "project-muted"
active   = "project-active"
action   = "project-actionable"
disabled = "project-disabled"

class ProjectsView extends Backbone.View
  events: ->
    isTouch = "ontouchstart" of window
    events  =
      "iostap .project-tag-link": "filterByTag"
      "click  .project-tag-link": "filterByTag"

    if isTouch
      events["iostap"] = "activate"
      events["click"] = "preventDefault"
    else
      events["mouseleave .project-link"] = "deactivate"
      events["mouseenter .project-link"] = "activate"

    return events

  activate: (e) ->
    e.stopImmediatePropagation()

    if @$(e.target).is(".project-close")
      @deactivate()
      return

    $link = @$(e.target).closest(klass)

    if $link.size() > 0
      if e.type is "iostap" and $link.hasClass(active)
        app.router.navigate($link.get(0).pathname, true)
      else
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
      @deactivate()

  deactivate: (e) ->
    @$(klass)
      .removeClass([muted, active, action].join(" "))

  filterByTag: (e) ->
    e.preventDefault()
    e.stopImmediatePropagation()

    tag = e.currentTarget.hash.slice(1)
    $el = @$(e.currentTarget).parents(".project-tag")
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

module.exports = ProjectsView
