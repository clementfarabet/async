local async = require 'async'

async.repl.listen({host='0.0.0.0', port=8484, prompt='bigbrother> '})

async.go()
