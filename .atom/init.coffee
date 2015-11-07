# Your init script
#
# Atom will evaluate this file each time a new window is opened. It is run
# after packages are loaded/activated and after the previous editor state
# has been restored.
#
# An example hack to log to the console when each text editor is saved.
#
# atom.workspace.observeTextEditors (editor) ->
#   editor.onDidSave ->
#     console.log "Saved! #{editor.getPath()}"

atom.commands.add 'atom-text-editor', 'exit-insert-mode-if-preceded-by-j': (e) ->
    editor = @getModel()
    pos = editor.getCursorBufferPosition()
    range = [pos.traverse([0,-1]), pos]
    console.log(range)
    lastChar = editor.getTextInBufferRange(range)
    if lastChar != "j"
        e.abortKeyBinding()
    else
        editor.backspace()
        atom.commands.dispatch(e.currentTarget, 'vim-mode:activate-normal-mode')

atom.commands.add 'atom-text-editor.vim-mode:not(.insert-mode)',
  'user:vim-mode-move-down-five-times': (event) ->
    atom.commands.dispatch event.target, 'vim-mode:move-down'
    atom.commands.dispatch event.target, 'vim-mode:move-down'
    atom.commands.dispatch event.target, 'vim-mode:move-down'
    atom.commands.dispatch event.target, 'vim-mode:move-down'
    atom.commands.dispatch event.target, 'vim-mode:move-down'

atom.commands.add 'atom-text-editor.vim-mode:not(.insert-mode)',
  'user:vim-mode-move-up-five-times': (event) ->
    atom.commands.dispatch event.target, 'vim-mode:move-up'
    atom.commands.dispatch event.target, 'vim-mode:move-up'
    atom.commands.dispatch event.target, 'vim-mode:move-up'
    atom.commands.dispatch event.target, 'vim-mode:move-up'
    atom.commands.dispatch event.target, 'vim-mode:move-up'

atom.commands.add 'atom-text-editor.vim-mode:not(.insert-mode)',
  'user:vim-mode-move-down-fifteen-times': (event) ->
    atom.commands.dispatch event.target, 'vim-mode:move-down'
    atom.commands.dispatch event.target, 'vim-mode:move-down'
    atom.commands.dispatch event.target, 'vim-mode:move-down'
    atom.commands.dispatch event.target, 'vim-mode:move-down'
    atom.commands.dispatch event.target, 'vim-mode:move-down'
    atom.commands.dispatch event.target, 'vim-mode:move-down'
    atom.commands.dispatch event.target, 'vim-mode:move-down'
    atom.commands.dispatch event.target, 'vim-mode:move-down'
    atom.commands.dispatch event.target, 'vim-mode:move-down'
    atom.commands.dispatch event.target, 'vim-mode:move-down'
    atom.commands.dispatch event.target, 'vim-mode:move-down'
    atom.commands.dispatch event.target, 'vim-mode:move-down'
    atom.commands.dispatch event.target, 'vim-mode:move-down'
    atom.commands.dispatch event.target, 'vim-mode:move-down'
    atom.commands.dispatch event.target, 'vim-mode:move-down'

atom.commands.add 'atom-text-editor.vim-mode:not(.insert-mode)',
  'user:vim-mode-move-up-fifteen-times': (event) ->
    atom.commands.dispatch event.target, 'vim-mode:move-up'
    atom.commands.dispatch event.target, 'vim-mode:move-up'
    atom.commands.dispatch event.target, 'vim-mode:move-up'
    atom.commands.dispatch event.target, 'vim-mode:move-up'
    atom.commands.dispatch event.target, 'vim-mode:move-up'
    atom.commands.dispatch event.target, 'vim-mode:move-up'
    atom.commands.dispatch event.target, 'vim-mode:move-up'
    atom.commands.dispatch event.target, 'vim-mode:move-up'
    atom.commands.dispatch event.target, 'vim-mode:move-up'
    atom.commands.dispatch event.target, 'vim-mode:move-up'
    atom.commands.dispatch event.target, 'vim-mode:move-up'
    atom.commands.dispatch event.target, 'vim-mode:move-up'
    atom.commands.dispatch event.target, 'vim-mode:move-up'
    atom.commands.dispatch event.target, 'vim-mode:move-up'
    atom.commands.dispatch event.target, 'vim-mode:move-up'
