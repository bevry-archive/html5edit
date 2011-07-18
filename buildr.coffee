# Requires
buildr = require 'buildr'

# Includes
config =
	srcPath: __dirname+'/src'
	outPath: __dirname+'/src'
	compress: true
	outStylePath: __dirname+'/src/html5edit.css'
	outScriptPath: __dirname+'/src/html5edit.js'
	srcLoaderPath: __dirname+'/src/html5edit.loader.js'
	scripts: [
		'script/contenteditable.coffee'
		'script/slice.coffee'
		'script/selection.coffee'
	]
	styles: [
		'style/html5edit.less'
	]


# Build
mercuryBuildr = buildr.createInstance(config)
mercuryBuildr.process (err) ->
	throw err if err
	console.log 'Building completed'
