# The Status of HTML5 Edit

## Working

- slices are working without splitting an element
- basic cleans are working
- reading and applying selections are working


## Not Working

- `.apply()` and `.clean()` work, however they cause the cursor to loose it's position if the cursor is in a series of empty elements - this is due to the htmlIndex to textIndex to htmlIndex conversion, which is lossy. The fix for this could be using `diff_match_patch` instead of this conversion
	- **why is this?** this happens because `a<p></p><p>|</p><p></p>b` has the same textIndex as `a<p></p><p>|</p><p></p>|b` - the latter is what is applied
- `.slice(start,finish)` is working, although it will not split an element as that is quite complicated


## Next Steps

- see if `diff_match_patch` implementation works (solves the selection issues)
	- if that doesn't work, then I will have to think very hard
	- for `.apply()` I can always do: `.select()` afterwards, but for `.clean()` that will require something advance OR a token insert