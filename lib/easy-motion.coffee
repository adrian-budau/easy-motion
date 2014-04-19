EasyMotionInputView = require './easy-motion-input-view'

class EasyMotion

module.exports =
  configDefaults:
    replaceCharacters: "ABCDEFGHIJKLMNOPQRSTUVWXYZ"

  activate: (state) ->
    atom.workspaceView.eachEditorView (editor) ->
      editor.command "easy-motion:start", ->
        input = new EasyMotionInputView(editor)
        input.insertBefore atom.workspaceView.find '.status-bar'
        if input.hasWords()
          input.focus()
        else
          input.remove()

  deactivate: ->

  serialize: ->
