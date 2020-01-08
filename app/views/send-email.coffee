# Obfuscate the email from crawlers that don't execute the page javascript
class SendEmailView extends Backbone.View
  initialize: ->
    @$el.attr("href", "moc.sgni-s@nehpets:otliam".split("").reverse().join(""))

module.exports = SendEmailView
