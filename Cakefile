muffin = require 'muffin'

option '-w', '--watch', 'continue to watch the files and rebuild them when they change'
option '-c', '--commit', 'operate on the git index instead of the working tree'

task 'build', 'compile postify', (options) ->
  muffin.run
    files: './src/**/*'
    options: options
    map:
      'src/app.coffee'                  : (matches) -> muffin.compileScript(matches[0], 'app.js', options)
      'src/client.coffee'               : (matches) -> muffin.compileScript(matches[0], 'public/javascripts/application.js', options)
      'src/(postify|posterous).coffee'  : (matches) -> muffin.compileScript(matches[0], "lib/#{matches[1]}.js", options)
