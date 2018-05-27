app = require "app"

$inbound = $outbound = null

cache = {}

class MainView extends Backbone.View

  events:
    "focus": "toggleLinkBehaviour"
    "keyup": "toggleLinkBehaviour"
    "keydown": "toggleLinkBehaviour"
    "iostap a[href]": "navigateWithoutDelay"
    "click a[href]": "preventDefault"
    "mousemove": "onMouseMove"
    "touchmove": "onMouseMove"

  initialize: ->
    $inbound = @$("#inbound")
    $outbound = @$("#outbound")

    debounced = _.debounce _.bind(@onResize, this), 300
    $(window).on "resize", debounced

    @$style = $("<style />")
    @$el.append(@$style)

  toggleLinkBehaviour: (e) ->
    if e.type is "keydown"
      @disableTap = e.metaKey or e.ctrlKey
    else
      @disableTap = false

    if [13, 32].indexOf(e.keyCode) > -1
      $el = $(document.activeElement)
      if $el.is("a[href]")
        e.preventDefault()
        $el.trigger("iostap") if e.type is "keyup"

    return

  # Clicking a link will either smooth scroll to the target element,
  # navigate using the Backbone router or provide the default behaviour
  # of setting the window location. Clicks modified by CMD or CTRL are
  # disabled to allow the normal behaviour to occur.
  navigateWithoutDelay: (e) ->
    el = e.currentTarget

    if el.hash
      e.preventDefault()
      $anchor = $(el)
      $target = $($anchor.attr('href'))
      $parent = $($anchor.data("parent") or document.scrollingElement)
      sx = $target.get(0).offsetLeft
      sy = $target.get(0).offsetTop
      mx = $parent.get(0).scrollWidth  - $parent.get(0).offsetWidth
      my = $parent.get(0).scrollHeight - $parent.get(0).offsetHeight
      if my or mx
        $parent.stop().animate
          scrollLeft: Math.min(sx, mx)
          scrollTop: Math.min(sy, my)
        , 800, "quintInOut"
      else
        $(document.scrollingElement).scrollTo $target.offset().top

    else if @disableTap
      false

    else if @isAllowed(el)
      e.preventDefault()

      $(document.scrollingElement).scrollTo 0, ->
        app.router.navigate(el.pathname, true)

      false

    else
      window.location = el.href

  preventDefault: (e) ->
    unless @disableTap and not e.currentTarget.hash
      e.preventDefault()
      false

  isAllowed: (el) ->
    el.origin is window.location.origin and
    not el.href?.match(/\.zip$/) and
    not $(el).data("follow")?

  # Display the current page, calling a display method on each active view and
  # enclassing the current page to reflect the page name.
  display: (pageName, params) ->
    key = params?.key or pageName

    if not @views
      @views = {}
      @createViews($inbound, params)

    else if @key is key
      view.display?() for view in @views

    else
      @transitionViews params, => @afterTransition()

    @key = key

  # Turn off events and flip the inbound and outbound containers.
  # Remove events and call a hide method on any child view. Finish
  # by loading the new page.
  transitionViews: (params, callback) ->
    window.clearTimeout @transitionTimeout

    url = Backbone.history.location.pathname

    for key, view of @views
      view.stopListening()
      view.undelegateEvents()

    @$el.addClass("loading")

    if response = cache[url]
      @onLoad(params, response, callback)
    else
      $.ajax
        url: url
        type: "GET"
        success: (response) =>
          cache[url] = response
          @onLoad(params, response, callback)


  # Insert the new title and content onto the page, and create a view
  # for any new component on the page. Fail silently if view doesn't
  # match a valid view name.
  onLoad: (params, response, callback) ->
    $resp = $(response)
    _inb  = $resp.filter("#inbound")

    @$el.removeClass("loading")

    if window.hljs
      _inb.find("pre code").each -> window.hljs.highlightBlock this

    $("head").find("title, meta").remove()
    $("head").prepend($resp.filter("title, meta"))

    $outbound.attr("class", _inb.attr("class"))

    $outbound.html(_inb.html())
    $outbound.get(0).offsetWidth

    $inbound.attr("id", "outbound")
    $outbound.attr("id", "inbound")

    for key, view of @views
      view.hide?($inbound, $outbound)
      delete @views[key]

    @createViews($outbound, params)

    callback()

  createViews: ($el, params) ->
    $el
      .find("[data-view], [data-require]")
      .each (i, el) =>
        try
          if el.dataset.view
            View = (require el.dataset.view)
            opts = _.extend {el}, params
            @views[el.dataset.view] = new View(opts)

          if el.dataset.require
            $.ajax
              url: el.dataset.require
              dataType: "script"
              async: true
              success: => @views[el.dataset.view]?.ready?()
        catch err
          throw err

  # Redelegate events on the main view and flip back the container elements.
  afterTransition: ->
    window.clearTimeout @transitionTimeout
    @transitionTimeout = window.setTimeout( =>
      $outbound.addClass "ready"
      $inbound.removeClass "ready"
      @swapContainers()
    , 600)

  swapContainers: ->
    _inb = $outbound
    _otb = $inbound
    $inbound = _inb
    $outbound = _otb
    $outbound.empty().removeAttr("class")

  onResize: ->
    view.trigger("resize") for key, view of @views

  onMouseMove: (e) ->
    e = e.touches[0] if e.touches
    w = window.innerWidth
    h = window.innerHeight
    x = e.clientX / w
    y = 1 - e.clientY / h

    h = 180 + (60 * y) % 60
    s = 100 - Math.abs(0.5 - x) * 100
    l = 40 + y * 25 + Math.abs(0.5 - x) * 10

    highlight = "hsl(#{h.toFixed(2)}, #{s.toFixed(2)}%, #{l.toFixed(2)}%)"

    @$style.html """
      .txt-hl { color: #{highlight}; }
      .bg-hl  { background-color: #{highlight}; }
    """

module.exports = MainView
