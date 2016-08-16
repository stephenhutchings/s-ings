module.exports = (cvs, r, threshold = 127, invert = false) ->
  fx = new CanvasEffects(cvs, {useWorker: false})
  StackBlur.canvasRGB(cvs, 0, 0, cvs.width, cvs.height, r)
  fx.threshold(threshold)
  fx.invert() if invert
