class HeaderView extends Backbone.View
  initialize: ->
    $(window).on "scroll", => @onScroll()

  onScroll: ->
    window.clearTimeout @timeout
    @timeout = window.setTimeout (=> @detectDirection()), 20

  detectDirection: ->
    y = Math.max(window.pageYOffset, 0)
    delta = 10

    if @currentState isnt (y >= delta)
      $("html").toggleClass("hide-nav", @currentState = y >= delta)

module.exports = HeaderView
