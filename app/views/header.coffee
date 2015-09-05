class HeaderView extends Backbone.View
  initialize: ->
    $(window).on "scroll", => @onScroll()

  onScroll: ->
    window.clearTimeout @timeout
    @timeout = window.setTimeout (=> @detectDirection()), 10

  detectDirection: ->
    y = Math.max(window.pageYOffset, 0)
    delta = 30

    if @currentState isnt (y >= delta)
      $("html").toggleClass("hide-nav", @currentState = y >= delta)

module.exports = HeaderView
