# Turns a text index into a html index
# "a <strong>b</strong> c d".textToHtmlIndex(2) > 10
String.prototype.textToHtmlIndex = (index) ->
	# Prepare
	parts = @split(/<|>/g)
	textIndex = 0
	htmlIndex = 0
	resutl = -1

	# Detect Indexes
	for part,i in parts
		# Increment for <|>
		if i then htmlIndex++

		# Adjust htmlIndex
		htmlIndex += part.length

		# Text node
		unless i % 2
			# Adjust textIndex
			textIndex += part.length

			# Reached?
			if textIndex > index
				result = htmlIndex - (textIndex - index)
				break
	
	# Return
	result

# Returns the current node depth of the index
# "a <strong>b</strong> c d".getTextIndexDepth(2) > 1
String.prototype.getTextIndexDepth = (index) ->
	# Prepare
	htmlIndex = @textToHtmlIndex(index)

	# Return
	@getHtmlIndexDepth(htmlIndex)

# Returns the current node depth of the index
# "a <strong>b</strong> c d".getHtmlIndexDepth(10) > 1
String.prototype.getHtmlIndexDepth = (index) ->
	# Prepare
	parts = @split(/<|>/g)
	depthIndex = 0
	htmlIndex = 0
	depthIndex = 0

	# Detect Depth
	for part,i in parts
		# Increment for <|>
		if i then htmlIndex++

		# Adjust
		htmlIndex += part.length

		# HTML node
		if i % 2
			if part.length
				if part[0] is '/'
					--depthIndex
				else
					++depthIndex
		
		# Reached?
		if htmlIndex >= index
			break
	
	# Return
	depthIndex

# Returns the current node depth of the index
# "a <strong>b</strong> c d".levelTextIndexes(2,5) > 2,22
String.prototype.levelTextIndexes = (start, finish) ->
	# Prepare
	startIndex = @textToHtmlIndex(start)
	finishIndex = @textToHtmlIndex(finish)

	# Return
	@levelHtmlIndexes(startIndex,finishIndex)

# Levels the playing field between two text indexes
# "a <strong>b</strong> c d".levelHtmlIndexes(10,22) > 2,22
String.prototype.levelHtmlIndexes = (startIndex, finishIndex) ->
	# Check
	if startIndex > finishIndex
		throw new Error('Start greater than finish!')
	
	# Prepare
	startDepth = @getHtmlIndexDepth(startIndex)
	finishDepth = @getHtmlIndexDepth(finishIndex)

	# Ensure indexes are on the same playing field
	if startDepth > finishDepth
		n = startDepth - finishDepth
		for i in [0...n]
			startIndex = @lastIndexOf('<', startIndex - 1)
	else if finishDepth > startDepth
		n = finishDepth - startDepth
		n = startDepth - finishDepth
		for i in [0...n]
			finishIndex = @indexOf('>', finishIndex + 1)
	
	# Return
	[ startIndex, finishIndex ]

# Returns a jQuery element for a text range
# $("a <strong>b</strong> c d").range(2,5) > $("<span class="partial"><strong>b</strong> c</span>")
$.fn.range = (start, finish) ->
	# Prepare
	$el = $(this)
	html = $el.html()

	# Check
	unless html
		return $el
	if start > finish
		throw new Error('$.fn.range was passed a start index greater than the finish index')

	# Check
	if (start? and finish?) isnt true
		throw new Error('$.fn.range was passed incorrect indexes')

	# Indexes
	[startIndex,finishIndex] = html.levelTextIndexes(start, finish)

	# Check
	if (startIndex? and finishIndex?) isnt true
		console.log [start,finish], $el.text(), html
		throw new Error('$.fn.range could not level indexes')

	# Check
	if startIndex? and finishIndex?
		console.log html.substring(startIndex, finishIndex)

		# Wrap range with a range element
		wrappedHtml = html.substring(0, startIndex)+
			'<span class="range new">'+
			html.substring(startIndex, finishIndex)+
			'</span>'+
			html.substring(finishIndex)
		
		# Apply range element
		$range = $el.html(wrappedHtml).find('span.range.new')
		if wrappedHtml isnt $el.html()
			throw new Error('range was not applied as expected')
		$range.removeClass 'new'
	else
		$range = $el
	
	# Return
	$range

# Clean ranges from the element
# $("a <strong><span class="range">b</span></strong> c d").cleanRanges() > $("a <strong>b</strong> c d")
$.fn.cleanRanges = ->
	# Prepare
	$this = $(this)

	# Clean
	while true
		$range = $this.find('.range:first')
		if $range.length is 0 then break
		$range.replaceWith $range.html()
	
	# Return
	$this

# Clean the element
$.fn.clean = ->
	# Prepare
	$this = $(this)

	# Ranges
	$this.cleanRanges()
