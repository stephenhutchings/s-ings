prefix = require("lib/prefix")

class HeaderView extends Backbone.View
  initialize: ->
    $(window).on "scroll", => @onScroll()
    $(window).on "resize", => @onResize()

    @onResize()
    @detectDirection()

  # Debounce scroll checks by 10ms to avoid overworking the browser
  onScroll: ->
    window.clearTimeout @timeout
    @timeout = window.setTimeout (=> @detectDirection()), 10

  # Toggle the "hide-nav" class on the document when scrolling within
  # a third of the viewports height of the bottom of the page
  detectDirection: ->
    y     = $(window).scrollTop()
    delta = @data.contentHeight - @data.viewportHeight * 1.33
    state = (y < -delta or y >= delta)

    if @state isnt state
      $("html").toggleClass("hide-nav", @state = state)

  # For each resize event, compute the current dimensions of relevant
  # elements and cache that information to limit DOM inspection
  onResize: ->
    @data =
      contentHeight:  $("body").height()
      viewportHeight: $(window).height()

  # Take an offset, scale, transition and opacity and return a CSS object
  style: (x, scale, transition, opacity = 0) ->
    css = { opacity }
    css[prefix "transform"]  = "translate3d(#{x}px,0,0) scale(#{scale},1)"
    css[prefix "transition"] = transition if transition?
    return css

  # When transitioning between views, move the old logo
  # element (halfway) to it's new position and move the
  # new one (halfway) from it's previous position
  hide: ($outbound, $inbound) ->
    $il  = $("#logo", $inbound)
    $ol  = $("#logo", $outbound)
    dist = $il.offset().left - $ol.offset().left

    return if dist is 0

    $il.css @style(-dist / 2, 2, "none")
    $il.offset()
    $ol.css @style( dist / 2, 2)

    window.setTimeout (=> $il.css @style(0, 1, "", 1)), 300

module.exports = HeaderView
