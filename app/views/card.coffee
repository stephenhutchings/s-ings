class CardView extends Backbone.View

  events:
    # "iostap button": "download"
    "input select, input, [contenteditable]": "update"
    "click a[href]": "allowDefault"
    "iostap a[href]": "allowDefault"
    "dragend #card": "onDragEnd"
    "dragover #card": "onDragEnd"
    "dragleave #card": "onDragEnd"
    "dragend #card": "onDragEnd"
    "drop #card": "onDrop"

  initialize: ->
    @updateClasses()
    @update()

  updateClasses: ->
    @$el.attr("class", "")
    @$("[name]").each (i, el) => @$el.addClass([el.name, el.value].join("-"))

  update: (e) ->
    window.clearTimeout @timeout
    @timeout = window.setTimeout (=>
      @updateClasses()
      @create()
    ), 300

  create: ->
    @$el
      .addClass("rendering")
      .removeClass("drag")
      .offset()

    window.domtoimage.toPng(
      @el.querySelector("#canvas")
      { dpi: 144 }
    ).then (data) =>
      @$el.removeClass("rendering")
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

  onDragEnd: (e) ->
    e.preventDefault()
    @$el.toggleClass("drag", e.type is "dragover")

  onDrop: (e) ->
    e.preventDefault()

    @$el.removeClass("drag")

    file = event.dataTransfer.files[0]
    reader = new FileReader()
    reader.onload = (e) =>
      @$("select").removeAttr("disabled")
      @$("#canvas-img").css("background-image", "url(\"#{e.target.result}\")")
      window.setTimeout (=> @create()), 300

    reader.readAsDataURL(file)

module.exports = CardView
