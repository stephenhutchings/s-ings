fs      = require("fs-extra")
logger  = require("loggy")
setup   = require("./lib/setup")
options = require('minimist')(process.argv.slice(2))

decodeBase64Image = (dataString) ->
  matches = dataString.match(/^data:([A-Za-z-+\/]+);base64,(.+)$/)

  if matches.length isnt 3
    new Error('Invalid input string')

  else
    new Buffer(matches[2], 'base64')


setup (err, window) ->
  if err
    throw err

  else
    experiment = window.require("experiments/#{options.method}")
    logger.log "Starting #{options.file}"

    experiment.draw options, (canvas) ->
      logger.log "Completed #{options.file}"
      data = decodeBase64Image(canvas.toDataURL())
      canvas.remove()
      fs.writeFile options.file, data, -> window.close()
