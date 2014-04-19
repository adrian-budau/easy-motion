{View} = require 'atom'

module.exports =
class LetterCoverView extends View
  @content: ->
    @div class: 'letter-cover', =>

  element: =>
    @get()

  initialize: (editorView, range, letter) =>
    @text(letter)
    {top, left} = editorView.pixelPositionForBufferPosition range.start

    width = editorView.pixelPositionForBufferPosition(range.end).left -
      left

    css =
      position: "absolute",
      top: top + "px",
      left: left + "px",
      width: width + "px",
      height: editorView.lineHeight + "px",

    @css css
