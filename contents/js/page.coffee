module.exports =
  initialize: ($) ->
    $html = $("html")

    # Touch
    tap = if "ontouchstart" of window then "touchend" else "click"

    isIE = window.navigator.userAgent.indexOf("MSIE ") isnt -1


    $(".project-link")
     .on("mouseenter", ->
      $html.addClass("hover")
    ).on("mouseleave", ->
      $html.removeClass("hover")
    )

    unless isIE
      # Ajaxify vars
      currentURL = document.location.href
      currentClass = $("html").attr("class")
      selector = "#container"
      request = null

      $html.addClass("ready")

      cancelQueuedTransitions = ->
        request.abort() if request
        $(selector)
          .clearQueue()
          .attr("style", "")

      replaceRootClass = (klass) ->
        $html
          .addClass(klass)
          .removeClass("loading")

        currentClass = klass

      updateHeaderLinks = (pattern) ->
        $(".nav-link").each ->
          el = $(this)
          el.toggleClass "active", !!el.html().match(new RegExp(pattern, "i"))

      replaceContent = (data, isPopState) ->
        html = $(data).filter(selector).html()
        title = $(data).filter("title").html()

        document.title = title

        cacheState(data, title) unless isPopState

        pattern =
          document.location.pathname.match(/\/[^\/]*/)[0].slice(1) or "about"

        window.setTimeout (->
          $(selector).html(html)
        ), 300

        window.setTimeout (->
          replaceRootClass(pattern)
        ), 600

        updateHeaderLinks(pattern)

      cacheState = (html, title) ->
        window.history.pushState(
          "html": html, "pageTitle": title
          "", currentURL
        )

      ajaxifyContent = ->
        cacheState($("html").get(0).outerHTML, document.title)

        window.onpopstate = (e) ->
          if e.state
            $html
              .removeClass(currentClass)
              .addClass("loading")

            replaceContent(e.state.html, true)

        $(document).on "click", "a[href!='#']", (e) ->
          href = $(e.currentTarget).attr "href"
          currentURL = e.currentTarget.href

          origin = window.location.origin
          origin ?= window.location.protocol + "//" + window.location.host

          isStandardURL = $(e.currentTarget).hasClass("follow-link")
          isExternalURL = !currentURL.match origin
          isCurrentPage = href is document.location.href or href is "#"

          unless isExternalURL or isStandardURL
            e.preventDefault()

            unless isCurrentPage
              $("html, body").not(":animated").animate scrollTop: 0

              $html
                .removeClass(currentClass)
                .addClass("loading")

              cancelQueuedTransitions()
              request = $.ajax
                url: currentURL
                success: (data) -> replaceContent(data)

      ajaxifyContent()

    return
