local async = dofile('async.lua')

async.repl.listen({host='0.0.0.0', port=8484, prompt='bigbrother> '})

async.go()
