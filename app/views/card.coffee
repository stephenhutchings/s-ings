class CardView extends Backbone.View

  events:
    # "iostap button": "download"
    "input select, input, [contenteditable]": "update"
    "click a[href]": "allowDefault"
    "iostap a[href]": "allowDefault"

  initialize: ->
    @update()

  update: (e) ->
    @$el.attr("class", "")
    @$("[name]").each (i, el) =>
      @$el.addClass([el.name, el.value].join("-"))

    window.clearTimeout @timeout
    @timeout = window.setTimeout (=> @create()), 300

  create: ->
    window.domtoimage.toPng(
      @el.querySelector("#canvas")
      { dpi: 144 }
    ).then (data) =>

      author = @$("h2").text().trim()
      quote  = @$("h1").text().trim()
      title  = [author, quote].join("-")
      fname  = title.replace(/\s+/g, "-").toLowerCase().slice(0, 50)

      @$("#preview").attr("src", data)

      @$("a")
        .attr("download", "#{fname}.png")
        .attr("href", data)
        .click()

  allowDefault: (e) ->
    e.stopImmediatePropagation()
    return true

module.exports = CardView
