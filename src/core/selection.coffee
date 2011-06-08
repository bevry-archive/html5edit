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
	while el.nodeType is 3
		el = el.parentNode
	$el = $(el)

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
		else
			false
	)

	# Return
	result

# Fetch node offset
# $('<div>a <span>b c</span> d</div>').getNodeOffset(4) > ['b c',2]
$.fn.getNodeOffset = (textIndex) ->
	# Prepare
	$parent = $(this)
	parent = $parent.get(0)
	result = null

	# Contents
	currentTextIndex = 0
	$parent.contents().each ->
		# Fetch
		$container = $(this)
		container = $container.get(0)
		text = $container.text()

		# Increment
		currentTextIndex += text.length
		unless currentTextIndex >= textIndex
			return true # continue
		
		# Calculate offset
		offset = textIndex-(currentTextIndex-text.length)

		# Element (not textnode)
		unless container.nodeType is 3
			result = $container.getNodeOffset(offset)
		else
			result = [container,offset]
		
		# Break
		return false

	# Return
	return result

# Expand an offset
$.fn.expandOffset = (container,offset) ->
	# Prepare
	$parent = $(this)
	parent = $parent.get(0)
	$container = $(container)
	container = $container.get(0)
	result = 0

	# Check to see if the container is the parent
	if $parent.same($container)
		console.log 'love child', [parent,container]
		result = offset

	# Check to see if the container is a 1st level child
	else if $parent.includes($container)
		console.log 'nested child', [parent,container]
		$parent.contents().each ->
			$el = $(this)
			el = $el.get(0)
			# Same
			if $el.same($container)
				result += offset
				return false
			# Intermediate
			else if (el.nodeType is 3) or !$el.includes($container)
				result += $el.text().length
				return true
			# Inside
			else
				result += $el.expandOffset(container,offset)
				return false

	# Error
	else
		console.log 'no level child', [parent,container]
		throw new Error('The child does not exist in the parent')
	
	# Return
	result


# Apply or Fetch the selectionRange
$.fn.selectionRange = (selectionRange) ->
	# Prepare
	$el = $(this)
	el = $el.get(0)
	result = this

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
			# TODO
			
			# Fetch
			selection = window.getSelection()
			selection.removeAllRanges()

			# Range Nodes
			[startNode,startOffset] = $el.getNodeOffset(selectionRange.selectionStart)
			[endNode,endOffset] = $el.getNodeOffset(selectionRange.selectionEnd)

			# Range
			range = document.createRange()
			range.selectNodeContents(el)
			range.setStart(startNode,startOffset)
			range.setEnd(endNode,endOffset)

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

			console.log('parent:',parent)

			# Level offsets
			console.log 'start'
			selectionStart = $el.expandOffset(range.startContainer,range.startOffset)
			console.log 'end'
			selectionEnd = $el.expandOffset(range.endContainer,range.endOffset)

			# Range
			selectionRange = {selectionStart,selectionEnd}
			
			# Result
			result = selectionRange
	
	# Return
	result

# Create or Fetch the range surrounding a selection
$.fn.selection = (selectionRange) ->
	# Prepare
	$el = $(this)
	el = $el.get(0)

	# Apply or Fetch
	if selectionRange?
		$el.selectionRange(selectionRange)
	else
		selectionRange = $el.selectionRange()
	
	console.log 'selectionRange:', selectionRange
	
	# Range
	if selectionRange?
		$range = $el.range(selectionRange.selectionStart,selectionRange.selectionEnd)
		$el.selectionRange(selectionRange) # re-apply, as range will change the dom
	else
		$range = $()
	
	# Return
	$range
