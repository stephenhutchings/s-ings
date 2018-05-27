class SendEmailView extends Backbone.View
  initialize: ->
    @$el.attr("href", "mailto:stephen@s-ings.com")

module.exports = SendEmailView
