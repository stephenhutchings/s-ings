class FontSelectorView extends Backbone.View

  events:
    "input input": "update"

  initialize: ->
    { @widths, @weights, target, label } = @$el.data()

    @$elements =
      width:  @$("[name='width']")
      weight: @$("[name='weight']")
      italic: @$("[name='italic']")
      size:   @$("[name='size']")
      target: @$(target)
      label:  @$(label)

  update: (e) ->
    width  = _.keys(@widths)[parseInt @$elements.width.val() - 1]
    weight = _.keys(@weights)[parseInt @$elements.weight.val() - 1]
    italic = @$elements.italic.is(":checked")
    size   = @$elements.size.val()

    wd = @widths?[width]
    wg = @weights?[weight]

    next = "f-g-#{wg or ""}#{wd or ""}"

    @$elements.target
      .removeClass(@currentClass)
      .addClass(@currentClass = next)
      .css(
        "font-size": size + "px"
        "line-height": (28 / 17) - size / 96 * 0.7
        "font-style": if italic then "italic" else ""
      )

    @$elements.label.html("#{weight or ""} #{width or ""} #{size}px")

module.exports = FontSelectorView
