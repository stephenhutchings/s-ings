_      = require("lodash")
fs     = require("fs-extra")
glob   = require("glob")
async  = require("async")
logger = require("loggy")

{fork} = require("child_process")

s = (s, n) -> "#{n} #{s}#{if n is 1 then "" else "s"}"

n = (i) ->
  name = (i + 1).toString()
  name = "0#{name}" while name.length < 3
  name

nextDir = (base) ->
  index = glob
    .sync("#{base}/*/")
    .sort()
    .map((d) -> +d.match(/\d+/)?[0])
    .reverse()[0]
  [base, n(index or 0)].join("/")

module.exports = (options) ->
  path = nextDir("./renders/#{options.method}")
  fs.mkdirsSync(path)

  logger.log "Drawing experiment '#{options.method}' #{s("time", options.amount)}"

  async.parallelLimit (
    for i in [0...options.amount]
      do (i) -> (d) ->
        opts = _.extend { file: "#{path}/#{n(i)}.png" }, options
        argv = ("--#{key}=#{val}" for key, val of opts when key isnt "_")

        child = fork "./utils/draw-one.coffee", argv
        child.on "exit",  d
        child.on "error", -> d("#{options.name} failed")

  ), 3, (err, res) ->
    if err
      throw err
    else
      logger.log "Completed #{res.length} #{s("file", res.length)}"
      process.exit()
