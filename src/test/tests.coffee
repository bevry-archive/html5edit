$ ->
	module 'Range'

	test 'standard range wrap', ->
		$content = $('<div>a b c d e</div>')
		$content.range(2, 5).wrap '<strong>'
		$content.cleanRanges()
		equals $content.html(), 'a <strong>b c</strong> d e'

	test 'stacked range wrap', ->
		$content = $('<div>a b c d e</div>')
		$content.range(2, 5).wrap '<strong>'
		$content.range(3, 7).wrap '<em>'
		$content.cleanRanges()
		equals $content.html(), 'a <em><strong>b c</strong> d</em> e'