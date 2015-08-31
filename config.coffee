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

    jade:
      baseDir: "app/templates"

    jadeStatic:
      baseDir: "app/static"
      formatPath: (path) ->
        path.match(/^app(\/|\\)static(\/|\\)(.+)\.jade$/)?[3]

      pretty: true
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
        "js/app.js": /^app/
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

  framework: "backbone"

