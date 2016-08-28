fs     = require("fs")
async  = require("async")
logger = require("loggy")
setup  = require("./lib/setup")

decodeBase64Image = (dataString) ->
  matches = dataString.match(/^data:([A-Za-z-+\/]+);base64,(.+)$/)

  if matches.length isnt 3
    new Error('Invalid input string')

  else
    new Buffer(matches[2], 'base64')

s = (s, n) -> "#{n} #{s}#{if n is 1 then "" else "s"}"

module.exports = (argv) ->
  logger.log "Seting up JSDOM..."
  setup (err, window) ->
    logger.log "JSDOM is ready"
    logger.log "Drawing experiment '#{argv.method}' #{s("time", argv.amount)}"

    experiment = window.require("experiments/#{argv.method}")

    async.parallelLimit (
      for i in [0...argv.amount]
        do (i) -> (d) ->
          name = (i + 1).toString()
          name = "0#{name}" while name.length < 3

          logger.log "Starting #{name}"

          experiment.draw argv, (canvas) ->
            logger.log "Completed #{name}"
            file = __dirname + "/examples/#{name}.png"
            data = decodeBase64Image(canvas.toDataURL())
            canvas.remove()
            fs.writeFile file, data, d

      ), 3, (err, res) ->
        if err
          throw err
        else
          logger.log "Completed #{res.length} #{s("file", res.length)}"
          window.close()
