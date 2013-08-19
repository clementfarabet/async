local async = dofile('async.lua')

async.repl.connect({host='127.0.0.1', port=8484})

async.go()
