$ ->
	# ContentEditable Change Event
	$('[contenteditable]')
		.live 'focus', ->
			$this = $(this)
			$this.data 'before', $this.html()
			$this
		.live 'blur keyup paste', ->
			$this = $(this)
			if $this.data('before') isnt $this.html()
				$this.trigger('change')
			$this