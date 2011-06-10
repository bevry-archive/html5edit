$ ->
	# Elements
	$style = $('#style')
	$content = $('#content')
	$code = $('#code')
	$selection = $('#selection')
	$wrap = $('#wrap')
	$clean = $('#clean')

	# Events
	update = (event) ->
		$code.text $content.html()
		sel = $content.htmlSelection()
		console.log 'sel:', sel
		$content.clean()
	$content.change(update).trigger('change')

	# Timer
	cleaner = ->
		$('[contenteditable]').clean()
	#setInterval cleaner, 1500

	# Wrap
	wrap = (event) ->
		element = prompt('enter element e.g. <strong> to wrap the selection in')
		unless element.length
			return
		$selection = $content.htmlSelection()
		unless $selection.length
			return
		$selection.wrap(element).apply().select(true)
		$content.trigger('change')
	$wrap.click(wrap)

	# Clean
	clean = (event) ->
		$content.clean()
		$content.trigger('change')
	$clean.click(clean)