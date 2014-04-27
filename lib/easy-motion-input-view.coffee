{View, EditorView, Range, $} = require 'atom'

_ = require 'underscore-plus'
CoverView = require './easy-motion-cover-view'

module.exports =
class EasyMotionInputView extends View
  wordStarts: []

  @content: ->
    @div class: 'easy-motion-input', =>
      @div class: 'editor-container', outlet: 'editorContainer', =>
      @subview 'editor', new EditorView(mini: true)

  initialize: (@realEditorView, @reverseMatch = false, options = {}) =>
    @cover = new CoverView(@realEditorView)
    @cover.appendTo @realEditorView.overlayer

    @realEditorView.addClass "easy-motion-editor"
    @editor.find('input').on 'textInput', @autosubmit
    @editor.find('input').on 'blur', @remove
    @editor.on "core:confirm", @confirm
    @editor.on "core:cancel", @goBack
    if options.noReloadOnScroll
      @subscribe @realEditorView.getEditor(),
        "scroll-top-changed scroll-left-changed",
        @goBack
    else
      @subscribe @realEditorView.getEditor(),
        "scroll-top-changed scroll-left-changed",
        _.debounce @resetWords, 50

    if options.noReloadOnResize
      @subscribe $(window), 'resize', @goBack
    else
      @subscribe $(window), 'resize', _.debounce @resetWords, 50

    @editor.on "core:page-up", =>
      @realEditorView.trigger "core:page-up"
    @editor.on "core:page-down", =>
      @realEditorView.trigger "core:page-down"

    @resetWords()

  resetWords: =>
    do @cover.clearLetterCovers
    @loadWords()
    @groupWords()

  hasWords: =>
    @wordStarts.length > 0

  autosubmit: (event) =>
    @pickWords event.originalEvent.data
    if @wordStarts.length > 1
      @groupWords()
    else
      @confirm()
    false

  remove: =>
    @cover.remove()
    @realEditorView.removeClass "easy-motion-editor"
    super()

  confirm: =>
    if not @reverseMatch
      @realEditorView.getEditor().setCursorBufferPosition @wordStarts[0].start
    else
      @realEditorView.getEditor().setCursorBufferPosition @wordStarts[0].end
    @goBack()

  goBack: =>
    @unsubscribe()
    @realEditorView.focus()
    @remove()

  focus: ->
    @editor.focus()

  groupWords: =>
    count = @wordStarts.length
    replaceCharacters = atom.config.get('easy-motion.replaceCharacters')
    buffer = @realEditorView.getEditor().getBuffer()

    last = 0

    @groupedWordStarts = {}

    for i in [0 ... replaceCharacters.length]
      take = Math.floor count / replaceCharacters.length
      if i < count % replaceCharacters.length
        take += 1

      @groupedWordStarts[replaceCharacters[i]] = []
      for wordStart in @wordStarts[last ... (last + take)]
        @groupedWordStarts[replaceCharacters[i]].push wordStart
        @cover.addLetterCover wordStart, replaceCharacters[i],
          single: take is 1

      last += take

  pickWords: (character) =>
    do @cover.clearLetterCovers
    if character of @groupedWordStarts and @groupedWordStarts[character].length
      @wordStarts = @groupedWordStarts[character]
      return

    # try different cases for alphabet letters
    if character != character.toLowerCase()
      character = character.toLowerCase()
    else if character != character.toUpperCase()
      character = character.toUpperCase()
    else
      return
    if character of @groupedWordStarts and @groupedWordStarts[character].length
      @wordStarts = @groupedWordStarts[character]

  loadWords: =>
    words = []
    buffer = @realEditorView.getEditor().getBuffer()

    wordStarts = []
    markBeginning = (obj) =>
      [beginWord, beginWordEnd] = [null, null]
      if not @reverseMatch
        beginWord = obj.range.start
        beginWordEnd = [beginWord.row, beginWord.column + 1]
      else
        beginWordEnd = obj.range.end
        beginWord = [beginWordEnd.row, beginWordEnd.column - 1]

      wordStarts.push new Range(beginWord, beginWordEnd)

    for rowRange in @getRowRanges()
      buffer.scanInRange @wordRegExp(), rowRange, markBeginning

    @wordStarts = wordStarts

  getRowRanges: =>
    buffer = @realEditorView.getEditor().getBuffer()
    top = @realEditorView.scrollTop()
    bottom = top + @realEditorView.height()

    beginRow = @binarySearch buffer.getLineCount(), (row) =>
      @realEditorView.pixelPositionForBufferPosition([row, 0]).top < top

    beginRow += 1

    endRow = @binarySearch buffer.getLineCount(), (row) =>
      position = @realEditorView.pixelPositionForBufferPosition([row, 0]).top
      height = @realEditorView.lineHeight
      position + height <= bottom

    (row for row in [beginRow..endRow] when @notFolded row).map (row) =>
      @getColumnRangeForRow row

  getColumnRangeForRow: (row) =>
    buffer = @realEditorView.getEditor().getBuffer()
    left = @realEditorView.scrollLeft()
    right = left + @realEditorView.width()

    columns = @realEditorView.getEditor().clipBufferPosition([row, Infinity])
    columns = columns.column + 1

    beginColumn = @binarySearch columns, (column) =>
      @realEditorView.pixelPositionForBufferPosition([row, column]).left < left

    beginColumn += 1

    endColumn = @binarySearch columns, (column) =>
      @realEditorView.pixelPositionForBufferPosition([row, column]).left <= right

    new Range([row, beginColumn], [row, endColumn])

  wordRegExp: =>
    nonWordCharacters = atom.config.get('editor.nonWordCharacters')
    new RegExp("[^\\s" + _.escapeRegExp(nonWordCharacters) +  "]+", "g")

  notFolded: (row) =>
    editor = @realEditorView.getEditor()
    row is 0 or not editor.isFoldedAtBufferRow(row) or
      not editor.isFoldedAtBufferRow(row - 1)

  binarySearch: (maxValue, compare) ->
    step = 1
    while step < maxValue
      step *= 2

    answer = -1
    while step > 0
      if answer + step >= maxValue
        step = step >> 1
        continue

      if compare(answer + step)
        answer += step

      step = step >> 1

    answer
