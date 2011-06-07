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
 
# Level an offset from a series of children to the parent
$.fn.levelOffset = (parent,offset) ->
	# Prepare
	$el = $(this)

	# Level
	while !$el.same($parent)
		# Prepare
		el = $el.get(0)
		$parent = $el.parent()

		# Cycle through contents
		$parent.contents().each ->
			# Desired
			if this is el
				return false
			# Text
			else if this.nodeType is 3
				offset += this.data.length
			# Element
			else
				offset += $(this).html().length
		
		# Level up
		$el = $el.parent()
	
	# Return
	offset
	

# Create or Fetch the range surrounding a selection
$.fn.selection = (range) ->
	# Apply?
	if range?

	# Fetch
	else
		# Fetch
		range = window.getSelection().getRangeAt(0)
		parent = range.commonAncestorContainer

		# Level parent
		while parent.nodeType is 3
			parent = parent.parentNode

		# Elements
		$parent = $(parent)
		$left = $(range.startContainer.parentNode)
		$right = $(range.endContainer.parentNode)
		left = range.startOffset
		right = range.endOffset

		# Level offsets
		left = $left.levelOffset($parent,left)
		right = $right.levelOffset($parent,right)

		# Range
		console.log($parent,left,right)
		$range = $parent.range(left,right)

		# Return
		$range