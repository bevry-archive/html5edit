###

# Slices

Please note the operation of slices is highly volatile atm as it is currently in the research & development stage. Chances are this will change in the future, or already has and is inaccurate.


## What are slices?

Slices allow you to obtain only a part of an element. For instance, I can do the following:

	$el = $('<div>012345</div>')
	$slice = $el.htmlSlice(2,4)
	$slice.html()
	> '23'

This is important as it allows you to treat slices just as normal jQuery elements. For instance, you could wrap a slice in a `<strong>` element by doing:

	$el = $('<div>012345</div>')
	$slice = $el.htmlSlice(2,4).wrap('<strong>').apply()
	$el.clean()
	$el.html()
	> '01<strong>23</strong>45'

We utilise `.apply()` and `.clean()` due to the current implementation of slices. Read the how for more information.


## How do slices work?

### The Current Implementation & Its Caveat

Current implementation:

	$el = $('<div>012345</div>')
	$slice = $el.htmlSlice(2,4).html('twothree')

	$slice.outerHtml()
	> '<span class="slice">twothree</span>'
	$el.html()
	> '012345'
	
	$slice.apply()

	$el.html()
	> '01<span class="slice">twothree</span>45'
	
	$el.clean()
	$el.html()
	> '01twothree45'

The pros of this is that slices return a jQuery element.


The cons of this is that slices must level their range, for instance if I have:

	$el = $('<div>01<strong>23</strong>45<strong>67</strong>89')
	$slice = $el.textSlice(3,7)

Then I will get the following slice:

	$slice.html()
	> '<strong>23</strong>45<strong>67</strong>'

Whereas give then range I actually specified, I probably expected the following instead:

	$slice.html()
	`3</strong>45</strong>6`


The benefit of this is that it means you can only get valid HTML as the output. So if I were to do the following:

	$slice.wrap('<em>').apply().clean()

I would actually get this as the output:

	$el.html()
	> 01<em><strong>23</strong>45<strong>67</strong></em>89

Instead of the following invalid html, which jQuery will not accept:
	
	$el.html()
	> 01<strong>2<em>3</strong>45</strong>6</em>7</strong>89


However, the above is not always ideal, for example perhaps I wanted to do the following:

	$slice.html('3456').apply().clean()
	$el.html()
	> 01<strong>234567</strong>89

When in reality this would actually return:

	$slice.html('3456').apply().clean()
	$el.html()
	> 01<strong>3456</strong>89

Which is uh-oh...



### Alternative Implemenations

As the current way of doing things is now always desired, we need to come up with alternative implementations to support a direct slice too.

Here are the current ideas.

### Leveling: the current implementation

Leveling is the current implementation. As it levels the depths of the nodes within a slice range. As already stated, it's pros are that you always get valid HTML, and it is effecient. Con is that it doesn't work will with diff patches.


### Raw: slices return a jQuery like object

With the this option, slices will return a jQuery like object which would implement its own jquery-like API. So with things like `.html()` coded from scratch on this new object. Such an implementation could look like this:

	
	$.fn.slice = (startIndex,finishIndex,indirect) ->
		if indirect
			# like implemented
		else
			return new DirectSlice(@,startIndex,finishIndex)

	class DirectSlice
		parent: $el
		startIndex: 3
		finishIndex: 7
		value: '3</strong>45<strong>6'

		constructor: (@parent,@startIndex,@finishIndex) ->

		html: (html) ->
			if html?
				@value = html
				return @
			else
				return @value
		
		wrap: (a,z) ->
			if z?
				@value = a+@value+z
			else
				@value = a+@value+z.replace(/\</,'</')
			return @
		
		apply: ->
			html = @parent.html()
			@parent.html(
				html.substring(0,@startIndex)+
				@value+
				html.substring(@finishIndex)
			)
			return @

The downside of this is that we can not longer have jQuery selectors and travers on the slice and there would be a lot of custom code needing to be written. Plus you could generate invalid HTML which would not be applied properly. E.g. the wrapping example.

The benefit is that it is great for content substitutions. E.g. applying diffs.


### Break: restructure parent element appropriatly

With this option, instead of levelling the indexes so that they we produce HTML, we instead restructure the elements HTML so we can keep the indexes the same.

For example, given the following:

	$el = $('<div>01<strong>23</strong>45<strong>67</strong>89')
	$el.textSlice(3,7).wrap('<em>').apply().clean()

Instead of getting this:

	$el.html()
	> '01<em><strong>23</strong>45<strong>67</strong></em>89'

We would get the following:

	$el.html()
	> '01<strong>2</strong><em><strong>3</strong>45<strong>6</strong></em><strong>7</strong>89'

Or the following, depending on how we choose to implement it:

	$el.html()
	> '01<strong>2<em>3</em></strong><em>45</em><strong><em>6</em>7</strong>89'

The downside of this is that changes would be a lot more expensive to apply, and you would end up with a lot more messier HTML. Plus it wouldn't work that well for applying diff patches to the contents of a slice.

The benefit of this is that you would always end up with valid HTML, and you can maintain the use of jQuery selectors, traversing and everything else jQuery on the slices.


### Comparison

Leveling works well for effeciency and may actually be desired from a lot of use points, especially as it will always generate clean and valid HTML. It's downside is that won't work with diff patches, and may produce counter-intuitive results.

Raw works well for diff patches, though its downside is that it can produce invalid HTML.

Break works well for always producing valid HTML and intuitive results. Its downside is that in order to produce a visual intuitive result, it applies messy HTML, plus it won't work with diff patches.


### Decision

The decision is to support all three implementations. Leveling will be the default, and the implementation can be overwrote by the data property (`data-slice-method`) on the element  which can be `level`, `raw`, or `break`. It can also be overwrote by providing the method as the third argument to the `$.fn.htmlSlice` method, like so `$el.htmlSlice(startIndex,finishIndex,method)`


###


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