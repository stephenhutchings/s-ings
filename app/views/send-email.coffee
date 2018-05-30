# Obfuscate the email from crawlers that don't execute the page javascript
class SendEmailView extends Backbone.View
  initialize: ->
    @$el.attr("href", "mailto:stephen@s-ings.com")

module.exports = SendEmailView
