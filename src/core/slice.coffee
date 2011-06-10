generateToken = ->
	return '!!'+Math.random()+'!!'

String.prototype.selectableLength = ->
	html = @.toString()
	text = html.replace(/(\&[0-9a-zA-Z]+\;)/g, ' ')
	return text.length

# Turns a text index into a html index
# "a <strong>b</strong> c d".textToHtmlIndex(2) > 10
String.prototype.textToHtmlIndex = (index) ->
	# Prepare
	html = @.toString()
	textIndex = 0
	htmlIndex = 0
	entityRegex = /(\&[0-9a-zA-Z]+\;)/g
	elementRegex = /(\<[0-9a-zA-Z]+\>)/g
	elementFirstRegex = /^\<[0-9a-zA-Z]+\>/
	entityFirstRegex = /^\&[0-9a-zA-Z]+\;/

	# Detect Indexes
	htmlParts = html.split(/<|>/g)
	for htmlPart,i in htmlParts
		# Html node
		if (i % 2) is 1
			# Adjust html index
			htmlIndex += htmlPart.length + 2

		# Text node
		else
			# Entities
			textParts = htmlPart.replace(entityRegex,'<$1>').split(/<|>/g)
			for textPart,ii in textParts
				# Adjust index
				htmlIndex += textPart.length
				
				# Entity
				if (ii % 2) is 1
					# Adjust indexes
					textIndex += 1
				
					# Reached?
					if textIndex > index
						break
				
				# Text node
				else
					# Apply indexes
					textIndex += textPart.length

					# Reached?
					if textIndex > index
						htmlIndex -= (textIndex - index)
						break

			# Reached?
			if textIndex > index
				break
	
	# Return
	htmlIndex

# Turns a text index into a html index
# "a <strong>b</strong> c d".textToHtmlIndex(2) > 10
String.prototype.htmlToTextIndex = (htmlIndex) ->
	# Prepare
	html = @.toString()

	# Detect
	token = generateToken()
	$html = $(html.substring(0,htmlIndex)+token+html.substring(htmlIndex))
	textIndex = $html.text().indexOf(token)

	# Return
	textIndex

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
String.prototype.levelHtmlIndexes = (start, finish) ->
	# Check
	if startIndex > finishIndex
		throw new Error('Start greater than finish!')
	
	# Prepare
	startIndex = start
	finishIndex = finish
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
			finishIndex = @indexOf('>', finishIndex + 1)+1

	#console.log 'level:', [startDepth,finishDepth], [start,finish], [startIndex,finishIndex]
	
	# Return
	[startIndex, finishIndex]

$.fn.textSlice = (start,finish) ->
	[startIndex,finishIndex] = html.levelTextIndexes(start,finish)
	$(this).htmlSlice(startIndex,finishIndex)
	
# Returns a jQuery element for a text slice
# $("a <strong>b</strong> c d").slice(2,5) > $("<span class="partial"><strong>b</strong> c</span>")
$.fn.htmlSlice = (start, finish) ->
	# Prepare
	$this = $(this)

	# Clone?
	clone = $this.data('slice-clone') || true
	$el = if clone then $this.clone() else $this
	html = $el.html()

	# Check
	unless html
		return $el
	if start > finish
		throw new Error('$.fn.slice was passed a start index greater than the finish index')

	# Check
	if (start? and finish?) isnt true
		throw new Error('$.fn.slice was passed incorrect indexes')

	# Level
	[startIndex,finishIndex] = html.levelHtmlIndexes(start,finish)

	# Check
	if (startIndex? and finishIndex?) isnt true
		throw new Error('$.fn.slice could not level indexes')

	# Check
	if startIndex? and finishIndex?
		#console.log html.substring(startIndex, finishIndex)

		# Wrap slice with a slice element
		wrappedHtml = html.substring(0, startIndex)+
			'<span class="slice new">'+
			html.substring(startIndex, finishIndex)+
			'</span>'+
			html.substring(finishIndex)
		
		# Apply slice element
		$slice = $el.html(wrappedHtml).find('span.slice.new')
		if wrappedHtml isnt $el.html()
			console.log wrappedHtml
			console.log $el.html()
			console.warn new Error('slice was not applied as expected')
		$slice.removeClass 'new'
	else
		$slice = $el
	
	# References
	if clone
		$slice.data('slice-parent-old', $this).data('slice-parent-new', $el)

	# Return
	$slice

# Turn an element's insides into its outsides
$.fn.puke = ->
	$this = $(this)
	$this.replaceWith $this.html()
	$this

# Clean slices from the element
# $("a <strong><span class="slice">b</span></strong> c d").cleanSlices() > $("a <strong>b</strong> c d")
$.fn.cleanSlices = ->
	# Prepare
	$this = $(this)

	# Clean
	while true
		$slice = $this.find('.slice:first')
		if $slice.length is 0 then break
		$slice.puke()
	
	# Return
	$this

# Apply the changes to a slice
$.fn.apply = ->
	$slice = $(this).addClass('apply')
	$originalOld = $slice.data('slice-parent-old')
	$originalNew = $slice.data('slice-parent-new')
	if !$originalOld or !$originalNew
		return $slice
	$originalOld.empty().append($originalNew.contents())
	$slice

# Clean the element
$.fn.clean = ->
	# Prepare
	$this = $(this)

	# Fetch selection
	selectionRange = $this.htmlSelectionRange()
	if selectionRange
		tokenStart = generateToken()
		tokenEnd = generateToken()
		html = $this.html()
		$this.html(
			html.substring(0,selectionRange.selectionStart) +
			tokenStart +
			html.substring(selectionRange.selectionStart,selectionRange.selectionEnd) +
			tokenEnd +
			html.substring(selectionRange.selectionEnd)
		)
		console.log 'one', selectionRange
		console.log html
		console.log $this.html()

	# Slices
	$this.cleanSlices()

	# Elements
	for elementType in ['strong','b','u','em','i','del','ins']
		$this.find(elementType).find(elementType).puke()
	
	# Reapply selection
	if selectionRange
		html = $this.html()
		tokenStartIndex = html.indexOf(tokenStart)
		tokenEndIndex = html.indexOf(tokenEnd)
		parts = [
			html.substring(0,tokenStartIndex)
			html.substring(tokenStartIndex+tokenStart.length,tokenEndIndex)
			html.substring(tokenEndIndex+tokenEnd.length)
		]
		#debugger
		if parts[2].length and /^\<\/(div|p)/.test(parts[2])
			parts[2] = ' '+parts[2]
		$this.html(parts.join(''))
		console.log 'two'
		console.log html
		console.log $this.html()
		selectionRange.selectionStart = tokenStartIndex
		selectionRange.selectionEnd = tokenEndIndex-tokenStart.length
		console.log html, selectionRange
		$this.htmlSelectionRange(selectionRange)

	# Return
	$this