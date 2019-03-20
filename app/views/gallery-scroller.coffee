prefix = require("lib/prefix")

class GalleryScrollerView extends Backbone.View

  initialize: ->
    $gallery = @$el.siblings(".gallery")

    @$bar  = $("<div class='gallery-pagination-indicator bg-hl'>")
    @$el.append(@$bar)

    @onResize($gallery)
    @handleScroll($gallery)

    @listenTo this, "resize", => @onResize($gallery)
    @listenTo this, "keydown", (code) => @onKeyPress(code)
    $gallery.on "scroll", (e) => @onScroll(e)

  undelegateEvents: ->
    @$el.siblings(".gallery").off("scroll")
    super arguments...

  onScroll: (e) ->
    @handleScroll($(e.currentTarget))

  # For each resize event, compute the current dimensions of relevant
  # elements and cache that information to limit DOM inspection
  onResize: ($gallery) ->
    @data =
      scrollWidth: $gallery.prop("scrollWidth")
      outerWidth: $gallery.outerWidth()
      childWidth: $gallery.children().last().outerWidth()
      sections: @$el.children().not(@$bar).length

    @handleScroll($gallery)

  handleScroll: ($gallery) ->
    y = $gallery.scrollLeft()
    d = y / (@data.scrollWidth - @data.childWidth) * (@data.sections - 1)
    i = Math.round(d)

    # Calculate the the current scroll position from the left hand side of
    # the current element. The last element is a special case, because it
    # may not be wide enough to fill the entire scroller but should still
    # seem to reach the end when no more scrolling is possible
    if Math.ceil(d) is @data.sections - 1
      j = y - @data.childWidth * (@data.sections - 2)
      x = j / @data.outerWidth + j / @data.childWidth
      d += x * (@data.outerWidth / @data.childWidth - 1)
      d = Math.min(d, @data.sections - 1)

    # Transform the indicator and add an active class to the current item
    @$bar.css(prefix("transform"), "translate3d(0, #{d * 100}%, 0)")
    @$el.children().removeClass("active").eq(i).addClass("active")

    # Keep track of the current position for future calculations
    @current = { offset: d, index: i, desired: @current?.desired }

  onKeyPress: (k) ->
    return unless k is "LEFT" or k is "RIGHT"

    return if $(document.activeElement).is("[contenteditable], input")

    l = @$el.children().length
    d = if @current.desired? then @current.desired else @current.offset

    d-- if k is "LEFT"
    d++ if k is "RIGHT"

    # Always try to move in the direction of the scroll by choosing the
    # appropriate rounding method, and ensure the resulting index is
    # within bounds
    fn = "ceil" if k is "LEFT"
    fn = "floor" if k is "RIGHT"
    i = Math.min(Math.max(Math[fn](d), 0), l - 1)

    # Now we have the index, we can trigger a tap to hijack the default
    # scrollTo behaviour. Call focus to ensure tabbing jumps of from
    # the right element.
    @$el.children().eq(i).trigger("iostap").focus()

    # The desired index keeps track of subsquent key presses while the
    # scroller is still in motion. We can release the information after
    # the scroll has taken place, in about 800ms
    @current.desired = i

    window.clearTimeout @timeout
    @timeout = window.setTimeout (=> delete @current.desired), 800

module.exports = GalleryScrollerView
