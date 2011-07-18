$.fn.firedPromiseEvent ?= (eventName) ->
	$el = $(this)
	result = (if $el.data('defer-' + eventName + '-resolved') then true else false)
	result

$.fn.createPromiseEvent ?= (eventName) ->
	$this = $(this)
	return $this if typeof $this.data('defer-' + eventName + '-resolved') isnt 'undefined'
	$this.data 'defer-' + eventName + '-resolved', false
	events = $.fn.createPromiseEvent.events = $.fn.createPromiseEvent.events or {
		bind: (callback) ->
			$this = $(this)
			$this.bind eventName, callback

		trigger: (event) ->
			$this = $(this)
			Deferred = $this.data('defer-' + eventName)
			unless Deferred
				specialEvent = $.event.special[eventName]
				specialEvent.setup.call this
				Deferred = $this.data('defer-' + eventName)
			$this.data 'defer-' + eventName + '-resolved', true
			Deferred.resolve()
			event.preventDefault()
			event.stopImmediatePropagation()
			event.stopPropagation()
			$this

		setup: (data, namespaces) ->
			$this = $(this)
			$this.data 'defer-' + eventName, new $.Deferred()

		teardown: (namespaces) ->
			$this = $(this)
			$this.data 'defer-' + eventName, null

		add: (handleObj) ->
			$this = $(this)
			Deferred = $this.data('defer-' + eventName)
			specialEvent = $.event.special[eventName]
			unless Deferred
				specialEvent.setup.call this
				return specialEvent.add.apply(this, [ handleObj ])
			Deferred.done handleObj.handler

		remove: (handleObj) ->
	}

	boundHandlers = []
	$.each ($this.data('events') or {})[eventName] or [], (i, event) ->
		boundHandlers.push event.handler

	$this.unbind eventName
	$this.bind eventName, events.trigger
	$.fn[eventName] = $.fn[eventName] or events.bind
	$.event.special[eventName] = $.event.special[eventName] or {
		setup: events.setup
		teardown: events.teardown
		add: events.add
		remove: events.remove
	}

	$.each boundHandlers, (i, handler) ->
		$this.bind eventName, handler

	$this

$ -> $('body').createPromiseEvent('html5edit-ready').trigger('html5edit-ready')
