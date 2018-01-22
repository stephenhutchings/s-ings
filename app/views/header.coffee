class HeaderView extends Backbone.View

  initialize: ->
    $(window).on "scroll", => @onScroll()
    @detectDirection()

  onScroll: ->
    window.clearTimeout @timeout
    @timeout = window.setTimeout (=> @detectDirection()), 10

  detectDirection: ->
    y = $(window).scrollTop()
    delta = 30
    newState = (y < -delta or y >= delta)

    if @currentState isnt newState
      $("html").toggleClass("hide-nav", @currentState = newState)

module.exports = HeaderView
