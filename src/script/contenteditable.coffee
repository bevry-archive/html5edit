$ -> # Enter event
	$.fn.enter = $.fn.enter or (data, callback) ->
	  $(this).binder("enter", data, callback)

	$.event.special.enter =
		setup: (data, namespaces) ->
			$(this).bind "keypress", $.event.special.enter.handler
		
		teardown: (namespaces) ->
			$(this).unbind "keypress", $.event.special.enter.handler
		
		handler: (event) ->
			$el = $(this)
			enterKey = event.keyCode is 13
			if enterKey
				event.type = "enter"
				$.event.handle.apply this, [ event ]
				return true
			return

	# ContentEditable Change Event
	$('[contenteditable]')
		.live 'focus', ->
			$this = $(this)
			$this.data 'before', $this.html()
			$this
		.live 'blur keyup paste', ->
			$this = $(this)
			html = $this.html()
			if $this.data('before') isnt html
				$this.data('before', html)
				$this.trigger('change')
			$this
		.live 'enter', ->
			$this = $(this)
			$sel = $this.htmlSelectionRange()
			cleaner = ->
				$this.find(':has(> br:first-child:last-child)').replaceWith('<p class="new p">&nbsp;&nbsp;</p>')
				found = true
				while found
					$p = $this.find('p.p > p.p')
					$p.appendTo($p.parent())
					found = $p.length
				$new = $this.find('p.p.new')
				if $new.length is 1
					$new.htmlSelectionRange(1,1).removeClass('new')
			#setTimeout cleaner, 500