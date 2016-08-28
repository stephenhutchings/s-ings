fs   = require("fs")
data = require("./utils/data")

exports.config =
  paths:
    public: "build"

  server:
    hostname: "0.0.0.0"

  conventions:
    ignored: [
      /[\\/]_/
      "node_modules"
      /^app\/static\/partials/
      /^app\/static(\/|\\)(.+)\.yaml$/
    ]

  plugins:
    autoprefixer:
      browsers: ["> 1%"]

    jade:
      staticPatterns: /^app(\/|\\)static(\/|\\)(.+)\.jade$/
      locals:
        _:        require("lodash")
        moment:   require("moment")
        typogr:   require("typogr")
        written:  require("written")
        package:  require("./package.json")
        data:     data

  files:
    javascripts:
      joinTo:
        "js/app.js": /^app\/((?!(chat|experiments)\/).)*$/
        "js/chat.js": /^app\/chat/
        "js/experiments.js": /^app\/experiments/
        "js/vendor.js": (path) -> /^(vendor|bower_components)/.test(path)

      order:
        before: [
          "bower_components/underscore/underscore.js"
          "bower_components/jquery/dist/jquery.js"
          "bower_components/moment/moment.js"
          "bower_components/backbone/backbone.js"
        ]

    stylesheets:
      joinTo:
        "css/app.css": "app/sass/app.sass"
        "css/experiments.css": "app/sass/experiments.sass"

    templates:
      joinTo:
        "js/app.js": /^app\/templates(\/|\\)(.+)\.jade$/

  framework: "backbone"

  hooks:
    onCompile: (generatedFiles) ->
      data.clearCache()

      for g in generatedFiles
        for f in g.sourceFiles
          if f.path.match "sitemap"
            fs.rename(
              "#{__dirname}/build/sitemap.xml.html",
              "#{__dirname}/build/sitemap.xml", (err) ->
                console.log err if err?
            )

