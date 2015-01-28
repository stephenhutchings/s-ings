module.exports =
  initialize: ($) ->
    lastScrollTop = 0
    state = null
    timeout = null
    delta = 50
    wait = 20

    detectDirection = ->
      y = Math.max(window.pageYOffset, 0)

      if state isnt (y >= lastScrollTop + delta)
        state = y >= lastScrollTop
        $("html")
          .toggleClass("hide-nav", state)
          .toggleClass("light-nav", y < -100)

      lastScrollTop = y

    $(window).on "scroll", ->
      window.clearTimeout timeout
      timeout = window.setTimeout (->
        detectDirection()
      ), wait
