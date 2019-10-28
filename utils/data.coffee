_         = require "lodash"
fs        = require "fs"
yaml      = require "js-yaml"
glob      = require "glob"
moment    = require "moment"

root  = "./app/static"
cache = {}

getAll = (type) ->
  cache[type] or glob
    .sync("#{root}/**/#{type}/*/")

    .map((m) ->
      getOne type, m.replace(type, "").replace(root, "").replace(/\//g, "")
    )

    .sort((a, b) ->
      moment(new Date b.date).toDate() - moment(new Date a.date).toDate()
    )

    .filter((m) ->
      not m.hide
    )

getOne = (type, name) ->
  path = "#{type}/#{name}/"
  data = { path }

  if cache[type]
    result = _.findWhere(cache[type], data)

  result or _.extend data,
    try
      if file = glob.sync("#{root}/#{path}*.yaml")?[0]
        yaml.load fs.readFileSync(file, "UTF-8")
      else
        console.log "No YAML data found for '#{root}/#{path}'"
        { hide: true }
    catch err
      console.error type, name, err
      { hide: true }

getFolders = (path) ->
  glob
    .sync("#{path}/*/")
    .map((m) -> m.replace(path, "").replace(/\//g, ""))

clear = ->
  cache = {}

module.exports = {
  getAll
  getOne
  getFolders
  clear
}
