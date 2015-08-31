app = require "app"

$inbound = $outbound = null

class MainView extends Backbone.View

  events:
    "iostap a[href]": "navigateWithoutDelay"
    "click a[href]": "navigateWithoutDelay"

  initialize: ->
    $inbound = @$("#inbound")
    $outbound = @$("#outbound")

  navigateWithoutDelay: (e) ->
    if e.currentTarget.hash
      $("body").scrollTo($(e.currentTarget.hash).offset().top - 48)
      false
    else if e.currentTarget.origin is window.location.origin
      e.preventDefault()
      app.router.navigate(e.currentTarget.pathname, true)
      false

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
      @transitionViews params, (callback) => @afterTransition(callback)

    @key = key

  # Turn off events, flip the inbound and outbound containers and scroll to
  # top. Remove events and call a hide method on any child view. Finish by
  # loading the new page.
  transitionViews: (params, callback) ->
    @undelegateEvents()

    $inbound.removeClass("ready")

    for key, view of @views
      view.stopListening()
      view.undelegateEvents()
      view.hide?()
      delete @views[key]

    $("body").scrollTo 0, =>
      $.ajax
        url: Backbone.history.location.pathname
        type: "GET"
        success: (response) => @onLoad(params, response, callback)

  # Insert the new title and content onto the page, and create a view for any
  # new component on the page. Fail silently if view doesn't match a valid view
  # name.
  onLoad: (params, response, callback) ->
    $resp = $(response)
    _inb  = $resp.filter("#inbound")

    if window.hljs
      _inb.find("pre code").each -> window.hljs.highlightBlock this

    document.title = $resp.filter("title").html()

    $outbound
      .html(_inb.html())
      .attr("class", _inb.attr("class"))

    $outbound.get(0).offsetWidth

    $inbound.attr("id", "outbound")
    $outbound.attr("id", "inbound")

    @createViews($outbound, params)

    callback()

  createViews: ($el, params) ->
    $el
      .find("[data-view]")
      .each (i, el) =>
        try
          View = (require el.dataset.view)
          opts = _.extend {el}, params
          @views[el.dataset.view] = new View(opts)
        catch err
          throw err

    $el.get(0).offsetWidth
    window.setTimeout (-> $el.addClass "ready"), 800


  # Redelegate events on the main view and flip back the container elements.
  afterTransition: (callback) ->
    window.clearTimeout @transitionTimeout
    @transitionTimeout = window.setTimeout( =>
      @delegateEvents()
      @swapContainers()
      callback?()
    , 600)

  swapContainers: ->
    _inb = $outbound
    _otb = $inbound
    $inbound = _inb
    $outbound = _otb
    $outbound.empty()

module.exports = MainView
