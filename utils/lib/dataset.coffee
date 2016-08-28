_ = require("underscore")

dashToCamel = (name) ->
  name.replace /-([a-z])/g, (g) -> g[1].toUpperCase()

getDataFrom = (element) ->
  data = {}

  for attr in element.attributes
    if attr.nodeName.indexOf('data-') is 0
      data[dashToCamel(attr.nodeName.slice(5))] = attr.nodeValue

  data

polyfillDataset = (parent = document.body) ->
  parent.dataset = getDataFrom(parent)
  polyfillDataset(child) for child in parent.children


module.exports = polyfillDataset
