# Creates a new zepto event called "iostap", which creates pseudo active
# states ("__active") for all elements that are touched.

module.exports =
  initialize: ->
    isTouch = "ontouchstart" of window

    return unless isTouch

    touch = null

    _start  = "touchstart"
    _move   = "touchmove"
    _end    = "touchend"
    _cancel = "touchcancel"
    _click  = "click"

    activeClass      = "__active"
    minimumActiveMS  = 50
    nearEnough       = false
    timeout          = null
    buffer           = 20
    maxDistance      = Math.pow(window.innerHeight * window.innerWidth, 0.35)

    parentIfText = (node) ->
      if "tagName" of node then node else node.parentNode

    parentIfData = (el) ->
      node = el

      while node.parentNode and not node.dataset?.touch
        node = node.parentNode

      if node?.dataset?.touch then node else el

    parentScrolls = (node) ->
      scrolls = false

      while node.parentNode and isTouch
        if scrolls = scrolls or node.scrollHeight > node.offsetHeight
          break
        else
          node = node.parentNode

      return scrolls and node

    toggleActiveState = (isActive) ->
      if isActive
        el = touch.el
        while el.parentNode
          el.classList.add activeClass
          break if el.dataset.nobubble
          el = el.parentNode
      else
        for el in document.querySelectorAll("." + activeClass)
          el.classList.remove activeClass

    onStart = (e) ->
      return if touch

      window.clearTimeout timeout

      el = parentIfText(e.target)
      el = parentIfData(el)

      touch =
        el: el
        offset: el.getBoundingClientRect()
        scrollParent: parentScrolls(el)

      onMove(e)

      bindEvent(_move, onMove, false)
      bindEvent(_end, onEnd, false)

    onMove = (e) ->
      return unless touch

      _e = if isTouch then e.touches[0] else e

      {clientX, clientY} = _e
      {width, top, left, height} = touch.offset

      touch.offset.startX ?= clientX
      touch.offset.startY ?= clientY
      touch.parentScrollY ?= touch.scrollParent?.scrollTop

      if touch.parentScrollY isnt touch.scrollParent?.scrollTop
        return onCancel()

      nearEnough = clientX > left - buffer and
                   clientX < left + width + buffer and
                   clientY > top - buffer and
                   clientY < top + height + buffer and
                   Math.abs(clientX - touch.offset.startX) < maxDistance and
                   Math.abs(clientY - touch.offset.startY) < maxDistance

      toggleActiveState(nearEnough)

    onEnd = (e) ->
      return unless touch

      unbindEvent(_move, onMove, false)
      unbindEvent(_end, onEnd, false)

      if nearEnough
        e.preventDefault()
        e.stopPropagation()

        {el, scrollParent} = touch

        tapEvent = document.createEvent "Event"
        tapEvent.initEvent "iostap", true, true

        unless scrollParent
          el.dispatchEvent(tapEvent)

        window.clearTimeout timeout
        timeout = window.setTimeout (->
          toggleActiveState(false)
          el.dispatchEvent(tapEvent) if scrollParent
        ), minimumActiveMS

      touch = null

    onCancel = ->
      return unless touch

      unbindEvent(_move, onMove, false)
      unbindEvent(_end, onEnd, false)

      touch = null
      toggleActiveState(false)

    onClick = (e) ->
      if isTouch
        e.preventDefault()
        return false

    bindEvent = (evt, fn, capture = false) ->
      window.addEventListener(evt, fn, capture)

    unbindEvent = (evt, fn, capture = false) ->
      window.removeEventListener(evt, fn, capture)

    Backbone?.on("canceltap", onCancel)

    bindEvent(_start, onStart, false)
    bindEvent(_click, onClick, false)
    bindEvent(_cancel, onCancel, false)
