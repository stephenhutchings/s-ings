;(function($){
  var scrollToTopInProgress = false;

  $.fn.scrollTo = function(position, callback){
    this.each(function(){
      var $this = $(this),
          initialY = $this.scrollTop(),
          maxY = this.scrollHeight - $this.outerHeight(),
          targetY = Math.min(position || 0, maxY),
          lastY = initialY,
          delta = targetY - initialY,
          speed = Math.max(800, Math.min(1200, Math.abs(initialY-targetY))),
          start, t, y,
          cancelScroll = function(){ abort() },
          frame = window.requestAnimationFrame ||
                  window.webkitRequestAnimationFrame ||
                  window.mozRequestAnimationFrame ||
                  function(callback){ window.setTimeout(callback,15) }

      if (scrollToTopInProgress) return
      if (delta == 0) {
        if (callback) callback($this, false)
        return
      }

      function smooth(pos){
        if ((pos/=0.5) < 1) return 0.5*Math.pow(pos,5)
        return 0.5 * (Math.pow((pos-2),5) + 2)
      }

      function abort(){
        $this.off('touchstart', cancelScroll)
        scrollToTopInProgress = false
        if (callback) callback($this, true)
      }

      $this.on('touchstart', cancelScroll)
      scrollToTopInProgress = true

      frame(function render(now){
        if (!scrollToTopInProgress) return
        if (!start) start = now
        t = Math.min(1, Math.max((now - start)/speed, 0))
        y = Math.round(initialY + delta * smooth(t))
        if (delta > 0 && y > targetY) y = targetY
        if (delta < 0 && y < targetY) y = targetY
        if (lastY != y) $this.scrollTop(y)
        lastY = y
        if (y !== targetY) {
          frame(render)
        } else {
          abort()
        }
      })
    })
    return this;
  }
})(jQuery || Zepto || $)
