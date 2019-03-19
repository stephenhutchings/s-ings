require.register "views/elevator", (exports, require, module) ->
  class CardView extends Backbone.View

    events:
      "input select, input, [contenteditable]": "update"
      "click a[href]": "allowDefault"
      "iostap a[href]": "allowDefault"
      "iostap #balance": "balanceText"
      "paste [contenteditable]": "onPaste"

    initialize: ->
      window.setTimeout =>
        @balanceText()
      , 10

    update: (e) ->
      window.clearTimeout @timeout
      @timeout = window.setTimeout (=>
        @create()
      ), 300

    create: ->
      @$el
        .addClass("rendering")
        .removeClass("drag")
        .offset()

      window.domtoimage.toJpeg(
        @el.querySelector("#canvas")
        { dpi: 144 }
      ).then (data) =>
        @$el.removeClass("rendering")
        fname = "Elevator-#{moment().format("MMM-DD")}"

        @$("#preview").attr("src", data)

        @$("#download")
          .attr("download", "#{fname}.jpg")
          .attr("href", data)
          .click()

    balanceText: ->
      @$(".balance-text").each (i, el) ->
        $el = $(el)
        str = $el.html()
        $el.html(str.replace(/\s+|<br[^>]+>/g, " "))
        window.balanceText(".balance-text")

      @update()

    allowDefault: (e) ->
      e.stopImmediatePropagation()
      return true

    onPaste: (e) ->
      $el = @$(".balance-text")

      window.setTimeout =>
        @balanceText()
      , 10


  module.exports = CardView
