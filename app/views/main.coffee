app = require "app"

$inbound = $outbound = null

class MainView extends Backbone.View

  events:
    "keyup": "toggleLinkBehaviour"
    "keydown": "toggleLinkBehaviour"
    "iostap a[href]": "navigateWithoutDelay"
    "click a[href]": "preventDefault"

  initialize: ->
    $inbound = @$("#inbound")
    $outbound = @$("#outbound")

  toggleLinkBehaviour: (e) ->
    @disableTap = e.type is "keydown"

  navigateWithoutDelay: (e) ->
    return if @disableTap

    if e.currentTarget.hash
      unless $(e.currentTarget).data("noscroll")?
        @$el.scrollTo($(e.currentTarget.hash).offset().top - 48)

    else if @isAllowed(e.currentTarget)
      e.preventDefault
      app.router.navigate(e.currentTarget.pathname, true)
      false

    else
      window.location = e.currentTarget.href

  preventDefault: (e) ->
    if not @disableTap and @isAllowed(e.currentTarget)
      e.preventDefault()
      false

  isAllowed: (el) ->
    el.origin is window.location.origin and
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
      @transitionViews params, (callback) => @afterTransition(callback)

    @key = key

  # Turn off events, flip the inbound and outbound containers and scroll to
  # top. Remove events and call a hide method on any child view. Finish by
  # loading the new page.
  transitionViews: (params, callback) ->
    $inbound.removeClass("ready")

    for key, view of @views
      view.stopListening()
      view.undelegateEvents()
      view.hide?()
      delete @views[key]

    @$el.scrollTo 0, =>
      $.ajax
        url: Backbone.history.location.pathname
        type: "GET"
        success: (response) =>
          rx = /<script[^<]+<\/script>/g
          @onLoad(params, response.replace(rx, ""), callback)

  # Insert the new title and content onto the page, and create a view for any
  # new component on the page. Fail silently if view doesn't match a valid view
  # name.
  onLoad: (params, response, callback) ->
    $resp = $(response)
    _inb  = $resp.filter("#inbound")

    if window.hljs
      _inb.find("pre code").each -> window.hljs.highlightBlock this

    document.title = $resp.filter("title").html()

    $("body").attr("class", _inb.data("class"))

    $outbound.html(_inb.html())
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
