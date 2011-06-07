$ ->
	# Elements
	$style = $('#style')
	$content = $('#content')
	$code = $('#code')
	$selection = $('#selection')

	# ContentEditable OnChange
	$('[contenteditable]')
		.live 'focus', ->
			$this = $(this)
			$this.data 'before', $this.html()
			return $this
		.live 'blur keyup paste', ->
			$this = $(this)
			if $this.data('before') isnt $this.html()
				$this.trigger('change')
			return $this
	
	# ContentEditable SelectionRange
	$.fn.selectionRange = (selectionRange) ->
		# Prepare
		$this = $(this)
		el = $this.get(0)

		# Apply
		if selectionRange?
			if $this.is('textarea')
				el.selectionStart = selectionRange.selectionStart
				el.selectionEnd = selectionRange.selectionEnd
			else if $this.is('[contenteditable')
				alert 'a'
			return el

		# Fetch
		else
			if $this.is('textarea')
				selectionRange =
					selectionStart: el.selectionStart
					selectionEnd: el.selectionEnd
			else if $this.is('[contenteditable')
				alert 'a'
			return selectionRange

	# Events
	update = (event) ->
		$code.text $content.html()
		$selection.text JSON.stringify $content.selectionRange()
	$content.change(update).trigger('change')