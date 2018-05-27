prefix = require("lib/prefix")

class HeaderView extends Backbone.View
  initialize: ->
    $(window).on "scroll", => @onScroll()
    $(window).on "resize", => @onResize()

    @onResize()
    @detectDirection()

  onScroll: ->
    window.clearTimeout @timeout
    @timeout = window.setTimeout (=> @detectDirection()), 10

  detectDirection: ->
    y     = $(window).scrollTop()
    delta = @size.content - @size.viewport * 1.33
    state = (y < -delta or y >= delta)

    if @state isnt state
      $("html").toggleClass("hide-nav", @state = state)

  onResize: ->
    @size =
      content:  $("body").height()
      viewport: $(window).height()

  style: (x, scale, transition, opacity = 0) ->
    css = { opacity }
    css[prefix "transform"]  = "translate3d(#{x}px,0,0) scale(#{scale},1)"
    css[prefix "transition"] = transition if transition?
    return css

  hide: ($outbound, $inbound) ->
    $il  = $("#header h4", $inbound)
    $ol  = $("#header h4", $outbound)
    dist = $il.offset().left - $ol.offset().left

    return if dist is 0

    $il.css @style(-dist / 2, 1.5, "none")
    $il.offset()
    $ol.css @style( dist / 2, 1.5)

    window.setTimeout (=> $il.css @style(0, 1, "", 1)), 300

module.exports = HeaderView
