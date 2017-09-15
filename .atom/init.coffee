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

{spawn} = require 'child_process'

# Open current file in broswer if it is a html
atom.commands.add 'atom-text-editor', 'Open In Broswer', ->
  editor = atom.workspace.getActiveTextEditor()
  if not editor
    return ''
  file = editor.getPath()
  if file.indexOf('.htm') isnt -1
    atom.notifications.addInfo 'opened', {dismissable: true}
    cp = spawn 'xdg-open ' + file, {shell: true}
    cp.stdout.on 'data', (data) ->
      console.log data.toString()
    cp.stderr.on 'data', (data) ->
      console.log data.toString()
  else
    atom.notifications.addInfo 'not html', {dismissable: true}
