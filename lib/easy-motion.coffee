EasyMotionInputView = require './easy-motion-input-view'
EasyMotionFindAndReplaceInputView = require './easy-motion-find-and-replace-input-view'
{$} = require 'atom'

class EasyMotion

module.exports =
  configDefaults:
    replaceCharacters: "ABCDEFGHIJKLMNOPQRSTUVWXYZ"

  activate: (state) ->
    setUpFindAndReplace = (editorView, reverseMatch = false) ->
      findAndReplaceView = editorView.closest('.find-and-replace').view()
      if findAndReplaceView.markers?.length
        input = new EasyMotionFindAndReplaceInputView(findAndReplaceView, reverseMatch)
        input.insertBefore atom.workspaceView.find '.status-bar'
        if input.hasWords()
          input.focus()
        else
          input.remove()

    atom.workspaceView.find('.find-and-replace .find-container .editor').each ->
      $(this).view().command "easy-motion:start-contextual", =>
        setUpFindAndReplace $(this).view()
      $(this).view().command "easy-motion:start-contextual-reverse", =>
        setUpFindAndReplace $(this).view(), true

    atom.workspaceView.on 'editor:attached', (event, editor) ->
      editor.command "easy-motion:start-contextual", =>
        setUpFindAndReplace editor
      editor.command "easy-motion:start-contextual-reverse", =>
        setUpFindAndReplace editor, true

    atom.workspaceView.eachEditorView (editor) ->
      editor.command "easy-motion:start", ->
        input = new EasyMotionInputView(editor, false)
        input.insertBefore atom.workspaceView.find '.status-bar'
        if input.hasWords()
          input.focus()
        else
          input.remove()
      editor.command "easy-motion:start-reverse", ->
        input = new EasyMotionInputView(editor, true)
        input.insertBefore atom.workspaceView.find '.status-bar'
        if input.hasWords()
          input.focus()
        else
          input.remove()

  deactivate: ->

  serialize: ->
