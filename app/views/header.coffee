class HeaderView extends Backbone.View
  initialize: ->
    $(window).on "scroll", => @onScroll()

  onScroll: ->
    window.clearTimeout @timeout
    @timeout = window.setTimeout (=> @detectDirection()), 10

  detectDirection: ->
    y = window.pageYOffset
    delta = 30

    if @currentState isnt (y < -delta or y >= delta)
      $("html").toggleClass("hide-nav", @currentState = not @currentState)

module.exports = HeaderView
