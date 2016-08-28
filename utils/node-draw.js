require("coffee-script/register")
argv = require('minimist')(process.argv.slice(2))
draw = require("./draw")

argv.method = argv._[0] || "stumped-v1.0.1"
argv.width  = argv.width  || 1000
argv.height = argv.height || 1000
argv.amount = argv.amount || 15

draw(argv)
