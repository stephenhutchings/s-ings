fs = require("fs")

exports.config =
  paths:
    public: "build"

  conventions:
    ignored: [
      /[\\/]_/
      /^app\/static\/partials/
      /^app\/static(\/|\\)(.+)\.yaml$/
    ]

  plugins:
    autoprefixer:
      browsers: ["> 1%"]

    jaded:
      staticPatterns: /^app(\/|\\)static(\/|\\)(.+)\.jade$/
      locals:
        _:        require("lodash")
        moment:   require("moment")
        typogr:   require("typogr")
        written:  require("written")
        package:  require("./package.json")
        data:     require("./utils/data")

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
        "css/app.css": /\.s[ac]ss/

    templates:
      joinTo:
        "js/app.js": /^app\/templates(\/|\\)(.+)\.jade$/

  framework: "backbone"

  onCompile: (generatedFiles) ->
    for g in generatedFiles
      for f in g.sourceFiles
        if f.path.match "sitemap"
          fs.rename(
            "#{__dirname}/build/sitemap.xml.html",
            "#{__dirname}/build/sitemap.xml", (err) ->
              console.log err if err?
          )

