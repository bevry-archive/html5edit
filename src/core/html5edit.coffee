$ ->
	# Elements
	$style = $('#style')
	$content = $('#content')
	$code = $('#code')
	$selection = $('#selection')
	$wrap = $('#wrap')

	# Events
	update = (event) ->
		$code.text $content.html()
		console.log $content.selection()
	$content.change(update).trigger('change')

	# Wrap
	wrap = (event) ->
		element = prompt('enter element e.g. <strong> to wrap the selection in')
		unless element.length
			return
		$selection = $content.selection()
		unless $selection.length
			return
		$selection.wrap(element)
		$content.clean()
		$content.trigger('change')
	$wrap.click(wrap)