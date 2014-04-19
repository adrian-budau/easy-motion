{View} = require 'atom'

LetterCoverView = require './easy-motion-letter-cover-view'

module.exports =
class CoverView extends View
  letterCovers: []

  @content: ->
    @div class: "easy-motion-cover", =>

  initialize: (@realEditorView) =>

  addLetterCover: (range, letter, options) =>
    letterCover = new LetterCoverView(@realEditorView, range, letter)
    @append letterCover.element
    @letterCovers.push letterCover

    if options.single
      letterCover.addClass 'single'
    else
      letterCover.addClass 'many'

  clearLetterCovers: =>
    do letterCover.remove for letterCover in @letterCovers
