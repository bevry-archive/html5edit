# Are two jQuery elements pointing to the same jQuery element?
$.fn.same = (b) ->
	# Prepare
	a = $(this)
	b = $(b)

	# Return
	a.get(0) is b.get(0)

# Fetch the elements outerHtml
$.fn.outerHtml = $.fn.outerHtml or ->
  $el = $(this)
  el = $el.get(0)
  outerHtml = el.outerHTML or new XMLSerializer().serializeToString(el)
  outerHtml

# Fetch the actual jQuery element of the node, useful for textnodes
$.fn.element = ->
	# Prepare
	$el = $(this)
	el = $el.get(0)

	# Cycle
	if el
		while el.nodeType is 3
			el = el.parentNode
		$el = $(el)
	else
		$el = $()

	# Return
	$el

$.fn.includes = (container) ->
	# Prepare
	$el = $(this)
	el = $el.get(0)
	$container = $(container)
	container = $container.get(0)

	# Discover
	result = (
		if $el.contents().filter($container).length
			'child'
		else if $el.find($container).length or $el.find($container.element()).length or $el.contents().filter($container.element()).length
			'deep'
		else if $el.same($container)
			'same'
		else
			false
	)

	# Return
	result

$.fn.elementStartLength = ->
	$this = $(this)
	outerHtml = $this.outerHtml()
	result =
		if outerHtml and outerHtml[0] is '<'
			outerHtml.replace(/>.+$/g,'>').length
		else
			0

$.fn.elementEndLength = ->
	$this = $(this)
	outerHtml = $this.outerHtml()
	result =
		if outerHtml and outerHtml[0] is '<'
			outerHtml.replace(/^.+</g,'<').length
		else
			0

$.fn.isElement = ->
	$this = $(this)
	outerHtml = $this.outerHtml()
	return outerHtml and outerHtml[0] is '<'

$.fn.rawHtml = ->
	$this = $(this)
	outerHtml = $this.outerHtml()
	result =
		if outerHtml and outerHtml[0] is '<'
			$this.html()
		else
			outerHtml

$.fn.nextContent = (recurse) ->
	recurse ?= true

	$a = $(this)
	current = $a
	exit = false
	found = false
	$a.parent().contents().each ->
		$b = $(this)
		current = $b
		if exit
			found = true
			return false
		if $b.same($a)
			exit = true
	if found is false
		current = $a.parent().nextContent(false)
	$(current)

# Fetch node offset
# $('<div>a <span>b c</span> d</div>').getNodeOffset(4) > ['b c',2]
$.fn.getNodeHtmlOffset = (htmlIndex) ->
	# Prepare
	$parent = $(this)
	parent = $parent.get(0)
	$contents = $parent.contents()

	# Prepare results
	result = null

	# Contents
	offset = 0
	$contents.each ->
		# Fetch
		$container = $(this)
		container = $container.get(0)
		htmlLength = $container.rawHtml().length
		startLength = $container.elementStartLength()

		# Adjust the offset
		offset += startLength

		# Approached our mark
		#console.log offset, htmlIndex, $container.outerHtml()
		if offset >= htmlIndex
			# Correct overshoot
			offset -= (offset-htmlIndex)
			localOffset = htmlIndex-offset

			# Got the right element
			if container.nodeType is 3
				result = [container,localOffset]
				return false
			
			# Try and delve deeper
			else
				result = $container.getNodeHtmlOffset(localOffset)
				unless result?
					result = [container,localOffset]
				return false
	
		# Our mark is soon
		else
			# Adjust the offset
			offset += htmlLength

			# Our mark is within
			if offset > htmlIndex
				# Delve deeper
				result = $container.getNodeHtmlOffset(htmlLength-(offset-htmlIndex))
				return false
			
			# Our mark is upcoming
			else
				offset += $container.elementEndLength()
		
		# Continue
		return true

	# Ensure
	unless result?
		html = $parent.rawHtml()
		htmlLength = html.length
		selectableLength = html.selectableLength()
		if htmlLength < htmlIndex
			result = [parent,htmlLength]
		else if htmlLength is htmlIndex
			$next = $parent.nextContent()
			if $next.length isnt 0
				result = [$next.get(0),0]
		else
			#debugger
			htmlIndex -= (htmlLength - selectableLength)
			result = [parent,htmlIndex]
	
	# Return
	return result

# Expand an offset
$.fn.expandHtmlOffset = (container,offset) ->
	# Prepare
	$parent = $(this)
	parent = $parent.get(0)
	$container = $(container)
	container = $container.get(0)
	result = 0
	includes = $parent.includes($container)

	# Check to see if the container is the parent
	if includes is 'same'
		#console.log 'love child', [parent,container]
		result = $parent.elementStartLength() + offset

	# Check to see if the container is a 1st level child
	else if includes
		#console.log 'nested child', [parent,container]
		$parent.contents().each ->
			$el = $(this)
			el = $el.get(0)
			# Same
			if $el.same($container)
				result += offset + $el.elementStartLength()
				return false
			# Intermediate
			else if (el.nodeType is 3) or !$el.includes($container)
				result += ($el.outerHtml() || $el.html() || $el.text()).length
				return true
			# Inside
			else
				result += $el.elementStartLength() + $el.expandHtmlOffset(container,offset)
				return false

	# Error
	else
		#console.log 'no level child', [parent,container]
		throw new Error('The child does not exist in the parent')
	
	# Return
	result


# Apply or Fetch the selectionRange
$.fn.htmlSelectionRange = (selectionRange) ->
	# Prepare
	$el = $(this)
	el = $el.get(0)
	result = this

	# Adjust
	if typeof selectionRange is 'number'
		if arguments.length is 2
			selectionRange = {
				selectionStart: arguments[0]
				selectionEnd: arguments[1]
			}
		else
			selectionRange = {
				selectionStart: arguments[0]
				selectionEnd: arguments[0]
			}

	# Textarea
	if $el.is('textarea')
		# Apply
		if selectionRange?
			# Apply
			el.selectionStart = selectionRange.selectionStart
			el.selectionEnd = selectionRange.selectionEnd

			# Result
			result = this
		
		# Fetch
		else
			# Fetch
			selectionRange =
				selectionStart: el.selectionStart
				selectionEnd: el.selectionEnd
			
			# Result
			result = selectionRange
	
	# Element
	else
		# Apply
		if selectionRange?
			# Check
			unless el
				return $el

			# Fetch
			selection = window.getSelection()
			selection.removeAllRanges()

			# Range
			range = document.createRange()
			#range.selectNodeContents(el)

			# Range Nodes
			if $el.text().length
				#debugger
				[startNode,startOffset] = $el.getNodeHtmlOffset(selectionRange.selectionStart)
				[endNode,endOffset] = $el.getNodeHtmlOffset(selectionRange.selectionEnd)
				range.setStart(startNode,startOffset)
				range.setEnd(endNode,endOffset)
				console.log endNode, endOffset, selectionRange.selectionEnd

			# Apply
			selection.addRange(range)

			# Result
			result = this
			
		# Fetch
		else
			# Fetch
			selection = window.getSelection()
			
			# Check
			unless selection.rangeCount
				return null
			
			# Fetch
			range = selection.getRangeAt(0)
			parent = range.commonAncestorContainer

			# Level parent
			while parent.nodeType is 3
				parent = parent.parentNode
			$parent = $(parent)

			# Check heirarchy
			try
				# Level start offset
				#debugger
				if true
					$start = $(range.startContainer).element()
					startOffset = $start.text().indexOf($(range.startContainer).text())
					startIndex = $start.html().textToHtmlIndex(startOffset+range.startOffset)
					selectionStart = $el.expandHtmlOffset($start,startIndex)
				else
					selectionStart = $el.expandHtmlOffset(range.startContainer,range.startOffset)

				# Level end offset
				if true
					$end = $(range.endContainer).element()
					endOffset = $end.text().indexOf($(range.endContainer).text())
					endIndex = $end.html().textToHtmlIndex(endOffset+range.endOffset)
					selectionEnd = $el.expandHtmlOffset($end,endIndex)
				else
					selectionEnd = $el.expandHtmlOffset(range.endContainer,range.endOffset)
				
				# Range
				selectionRange = {selectionStart,selectionEnd}
			
				# Result
				result = selectionRange
			
			catch err
				result = null
	
	# Return
	result

# Create or Fetch the range surrounding a selection
$.fn.htmlSelection = (selectionRange) ->
	# Prepare
	$el = $(this)
	el = $el.get(0)

	# Apply or Fetch
	if selectionRange?
		$el.htmlSelectionRange(selectionRange)
	else
		selectionRange = $el.htmlSelectionRange()
	
	#console.log 'selectionRange:', selectionRange
	
	# Range
	if selectionRange?
		#debugger
		$slice = $el.htmlSlice(selectionRange.selectionStart,selectionRange.selectionEnd)
	else
		$slice = $()
	
	# Return
	$slice

# Select the current element
$.fn.select = (all) ->
	# Prepare
	$el = $(this)
	all or= false

	# Range
	selectionRange =
		selectionStart: 0
		selectionEnd: if all then $el.rawHtml().length else 0
	
	# Select
	$el.htmlSelectionRange(selectionRange)
	if $el.is('input')
		$el.focus()
	else
		$el.parents('#content').contents().focus()
	
	# Return
	$el