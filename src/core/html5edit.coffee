$ ->
	# Elements
	$style = $('#style')
	$content = $('#content')
	$code = $('#code')
	$selection = $('#selection')

	# Events
	update = (event) ->
		$code.text $content.html()
		console.log $content.selection()
	$content.change(update).trigger('change')