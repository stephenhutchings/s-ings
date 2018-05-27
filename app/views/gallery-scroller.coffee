prefix = require "lib/prefix"

class GalleryScrollerView extends Backbone.View

  initialize: ->
    @ready()

  ready: ->
    $gallery = @$el.siblings(".gallery")

    @$bar  = $("<div class='gallery-pagination-indicator bg-hl'>")
    @$el.append(@$bar)

    @onResize($gallery)
    @handleScroll($gallery)

    @listenTo this, "resize", => @onResize($gallery)
    $gallery.on "scroll", (e) => @onScroll(e)

  undelegateEvents: ->
    @$el.siblings(".gallery").off("scroll")

  onScroll: (e) ->
    @handleScroll($(e.currentTarget))

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

    if Math.ceil(d) is @data.sections - 1
      j = y - @data.childWidth * (@data.sections - 2)
      x = j / @data.outerWidth + j / @data.childWidth
      d += x * (@data.outerWidth / @data.childWidth - 1)
      d = Math.min(d, @data.sections - 1)

    @$bar.css(
      prefix("transform")
      "translate3d(0, #{d * 100}%, 0)"
    )

    @$el.children().removeClass("active").eq(i).addClass("active")

module.exports = GalleryScrollerView
