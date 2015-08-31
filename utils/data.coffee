_         = require "lodash"
fs        = require "fs"
yaml      = require "js-yaml"
glob      = require "glob"
marked    = require "marked"
moment    = require "moment"

paths =
  projects: "app/static/projects"

getProjects = ->
  glob
    .sync("#{paths.projects}/*/")

    .map((m) ->
      getProject m.replace(paths.projects, "").replace(/\//g, "")
    )

    .sort((a, b) ->
      moment(new Date b.date).toDate() - moment(new Date a.date).toDate()
    )

    .filter((m) ->
      not m.hide
    )

getProject = (name) ->
  path = "#{paths.projects}/#{name}/"

  _.extend { path: path.replace("app/static", "") },
    try
      yaml.load fs.readFileSync("#{path}project.yaml", "UTF-8")
    catch
      {}

module.exports = {
  getProjects
  getProject
}
