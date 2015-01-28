# require("js/jquery")

$ = require("./jquery")
page = require("./page")
scroll = require("./scroll")

$ ->
  page.initialize($)
  scroll.initialize($)
