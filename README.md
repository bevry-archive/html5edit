# HTML5 Edit

HTML5 Edit is currently in the research and development phase. Its focus is HTML5's contenteditable feature, and goal is to find better ways of interacting with it.


## Trying it Out

HTML5 Edit needs to be running on a server to work

### For Apache Developers

1. Clone `html5edit` to your htdocs

2. Open `htp://localhost/html5edit/lib/demo/src/index.html` in your browser


### For Node.js Developers

1. [Install Node.js](https://github.com/balupton/node/wiki/Installing-Node.js)

1. Install [CoffeeScript](http://jashkenas.github.com/coffee-script/) and [Simple-Server](https://github.com/balupton/simple-server)

		npm -g install coffee-script simple-server

1. Clone `html5edit`, `cd` into it, and install pre-requisites

	git clone https://github.com/balupton/html5edit.git
	cd html5edit
	npm install

1. Start the demo server

		./bin/html5edit.coffee

1. Open `http://localhost:3000/lib/demo/src/index.html` in your browser


## Learning

[HTML5 Edit's wiki is the best place to learn about it.](https://github.com/balupton/html5edit/wiki)


## History

- v0.2 June 12, 2011
	- Now working with Leveling Slices
	- Still need to implement other slicing styles

- v0.1 June 8, 2011
	- Initial commit


## License

Licensed under the [MIT License](http://creativecommons.org/licenses/MIT/)
Copyright 2011 [Benjamin Arthur Lupton](http://balupton.com)
