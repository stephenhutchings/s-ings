fs   = require("fs")
data = require("./utils/data")

exports.config =
  paths:
    public: "build"

  server:
    hostname: "0.0.0.0"

  conventions:
    assets: /app\/(assets|static)\//
    ignored: [
      /[\\/]_/
      "node_modules"
      /^app\/static\/partials/
      /^app\/static(\/|\\)(.+)\.yaml$/
      /\.(tmp\$\$)$/
    ]

  plugins:
    autoprefixer:
      browsers: ["> 1%"]

    pug:
      staticBasedir: "app/static/"
      locals:
        _:        require("lodash")
        moment:   require("moment")
        typogr:   require("typogr")
        written:  require("written")
        marked:   require("marked")
        package:  require("./package.json")
        data:     data

    coffeelint:
      pattern: /^app\/.*\.coffee$/

      options:
        no_empty_param_list:
          level: "error"

        prefer_english_operator:
          value: true
          level: "warn"

        indentation:
          value: 2
          level: "warn"

        max_line_length:
          level: "warn"

    postcss:
      processors: [
        require("autoprefixer")(["> 1%"])
        require("csswring")({ preserveHacks: true })
      ]

  overrides:
    production:
      plugins:
        pug:
          staticPretty: false

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
        "js/app.js": /^app\/templates(\/|\\)(.+)\.pug$/

  framework: "backbone"

  hooks:
    onCompile: (generatedFiles) ->
      for g in generatedFiles
        for f in g.sourceFiles
          if f.path.match "sitemap"
            fs.rename(
              "#{__dirname}/build/sitemap.xml.html",
              "#{__dirname}/build/sitemap.xml", (err) ->
                console.log err if err?
            )
