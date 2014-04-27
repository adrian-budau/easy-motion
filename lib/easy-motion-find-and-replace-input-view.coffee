{EditorView, Range} = require 'atom'

EasyMotionInputView = require './easy-motion-input-view'
_ = require 'underscore-plus'

module.exports =
class EasyMotionFindAndReplaceInputView extends EasyMotionInputView
  @content: ->
    @div class: 'easy-motion-input easy-motion-find-and-replace', =>
      @div class: 'editor-container', outlet: 'editorContainer', =>
      @subview 'editor', new EditorView(mini: true)

  initialize: (@findAndReplaceView, reverseMatch = false) =>
    super atom.workspaceView.getActiveView(), reverseMatch

  loadWords: =>
    @wordStarts = @findAndReplaceView.markers.map( (marker) =>
      [start, next] = [null, null]
      if not @reverseMatch
        start = marker.bufferMarker.getStartPosition()
        next = [start.row, start.column + 1]
        next = @realEditorView.getEditor().clipBufferPosition(next)
      else
        next = marker.bufferMarker.getEndPosition()
        start = [next.row, next.column - 1]
        start = @realEditorView.getEditor().clipBufferPosition(start)

      if start.column != next.column and @notFolded(start.row) and
          @isPositionVisible(start) and @isPositionVisible(next)
        [new Range(start, next)]
      else
        []
    )
    @wordStarts = _.flatten(@wordStarts)

  isPositionVisible: (position) =>
    top = @realEditorView.scrollTop()
    bottom = top + @realEditorView.height()
    left = @realEditorView.scrollLeft()
    right = left + @realEditorView.width()
    lineHeight = @realEditorView.lineHeight

    pixelPosition = @realEditorView.pixelPositionForBufferPosition(position)
    if left <= pixelPosition.left and pixelPosition.left <= right
      if top <= pixelPosition.top and pixelPosition.top + lineHeight <= bottom
        return true
    false

  confirm: =>
    if not @reverseMatch
      @realEditorView.getEditor().setCursorBufferPosition @wordStarts[0].start
    else
      @realEditorView.getEditor().setCursorBufferPosition @wordStarts[0].end

    @unsubscribe()
    @realEditorView.focus()
    @remove

  goBack: =>
    @unsubscribe()
    @findAndReplaceView.find('.find-container .editor').focus()
    @remove()
