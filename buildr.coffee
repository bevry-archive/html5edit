# Requires
buildr = require 'buildr'

# Includes
config =
	srcPath: __dirname+'/lib'
	outPath: __dirname+'/lib'
	compress: true
	outStylePath: __dirname+'/lib/html5edit.css'
	outScriptPath: __dirname+'/lib/html5edit.js'
	srcLoaderPath: __dirname+'/lib/html5edit.loader.js'
	srcLoaderHeader: '''
		# Prepare
		html5editEl = document.getElementById('html5edit-include')
		html5editBaseUrl = html5editEl.src.replace(/\\?.*$/,'').replace(/html5edit.loader\\.js$/, '').replace(/\\/+$/, '')+'/'

		# Load in with Buildr
		html5editBuildr = new window.Buildr {
			baseUrl: html5editBaseUrl
			beforeEl: html5editEl
			serverCompilation: window.serverCompilation or false
			scripts: scripts
			styles: styles
		}
		html5editBuildr.load()
		''' # note, all \ in this are escaped due to it being in a string
	scripts: [
		'script/contenteditable.coffee'
		'script/slice.coffee'
		'script/selection.coffee'
		'script/loaded.coffee'
	]
	styles: [
		'style/html5edit.less'
	]


# Build
html5editBuildr = buildr.createInstance(config)
html5editBuildr.process (err) ->
	throw err if err
	console.log 'Building completed'
