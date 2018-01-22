app = require "app"

$inbound = $outbound = null

cache = {}

class MainView extends Backbone.View

  events:
    "keyup": "toggleLinkBehaviour"
    "keydown": "toggleLinkBehaviour"
    "iostap a[href]": "navigateWithoutDelay"
    "click a[href]": "preventDefault"

  initialize: ->
    $inbound = @$("#inbound")
    $outbound = @$("#outbound")

    debounced = _.debounce _.bind(@onResize, this), 300
    $(window).on "resize", debounced

  toggleLinkBehaviour: (e) ->
    if e.metaKey or e.ctrlKey
      @disableTap = e.type is "keydown"

  navigateWithoutDelay: (e) ->
    if e.currentTarget.hash
      e.preventDefault()
      $anchor = $(e.currentTarget)
      $target = $($anchor.attr('href'))
      $parent = $($anchor.data("parent") or document.scrollingElement)
      sx = $target.get(0).offsetLeft
      sy = $target.get(0).offsetTop
      mx = $parent.get(0).scrollWidth - $parent.get(0).offsetWidth
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

    else if @isAllowed(e.currentTarget)
      e.preventDefault()
      app.router.navigate(e.currentTarget.pathname, true)
      false

    else
      window.location = e.currentTarget.href

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

  # Turn off events, flip the inbound and outbound containers and scroll to
  # top. Remove events and call a hide method on any child view. Finish by
  # loading the new page.
  transitionViews: (params, callback) ->
    url = Backbone.history.location.pathname

    for key, view of @views
      view.stopListening()
      view.undelegateEvents()
      view.hide?()
      delete @views[key]

    @$el.addClass("loading")

    $(document.scrollingElement).scrollTo 0, =>
      if response = cache[url]
        @onLoad(params, response, callback)
      else
        $.ajax
          url: url
          type: "GET"
          success: (response) =>
            cache[url] = response
            @onLoad(params, response, callback)

  # Insert the new title and content onto the page, and create a view for any
  # new component on the page. Fail silently if view doesn't match a valid view
  # name.
  onLoad: (params, response, callback) ->
    $resp = $(response)
    _inb  = $resp.filter("#inbound")

    if window.hljs
      _inb.find("pre code").each -> window.hljs.highlightBlock this

    $("head").find("title, meta").remove()
    $("head").prepend($resp.filter("title, meta"))

    $outbound.attr("class", _inb.attr("class"))

    $outbound.html(_inb.html())
    $outbound.get(0).offsetWidth

    window.setTimeout =>
      $inbound.attr("id", "outbound")
      $outbound.attr("id", "inbound")

      @createViews($outbound, params)

      callback()
    , 10

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
      $inbound.removeClass "ready"
      $outbound.addClass "ready"
      @$el.removeClass("loading")
      @swapContainers()
    , 600)

  swapContainers: ->
    _inb = $outbound
    _otb = $inbound
    $inbound = _inb
    $outbound = _otb
    $outbound.empty()

  onResize: ->
    view.trigger("resize") for key, view of @views

module.exports = MainView
