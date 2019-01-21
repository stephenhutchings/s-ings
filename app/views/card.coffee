class CardView extends Backbone.View

  events:
    "input select, input, [contenteditable]": "update"
    "click a[href]": "allowDefault"
    "iostap a[href]": "allowDefault"
    "iostap #balance": "balanceText"
    "dragend #card": "onDragEnd"
    "dragover #card": "onDragEnd"
    "dragleave #card": "onDragEnd"
    "dragend #card": "onDragEnd"
    "drop #card": "onDrop"
    "paste [contenteditable]": "onPaste"

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

      @$("#download")
        .attr("download", "#{fname}.png")
        .attr("href", data)
        .click()

  balanceText: ->
    $el = @$(".balance-text")
    str = $el.html()
    $el.html(str.replace(/\s+|<br[^>]+>/g, " "))
    window.balanceText(".balance-text")
    @update()

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

  onPaste: (e) ->
    $el = @$(".balance-text")

    window.setTimeout ->
      txt = $el.html().replace(/\s+|<[^>]+>/g, " ")
      console.log txt
      $el.html(txt)
      window.balanceText(".balance-text")
    , 10


module.exports = CardView
