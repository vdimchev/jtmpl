jtmpl<br>MVVM Templating Engine for the Browser
===============================================

jtmpl renders [Mustache](https://github.com/janl/mustache.js)-compatible template using a `model` object and automatically binds fields and events to DOM elements.


What
-----

* it's a templating engine

* it's a [MVVM](http://en.wikipedia.org/wiki/Model_View_ViewModel) micro-framework

* based on [Object.observe](http://updates.html5rocks.com/2012/11/Respond-to-change-with-Object-observe)

* no dependencies (Object.observe [polyfill](https://github.com/jdarling/Object.observe) is built-in)

* IE 8+, Firefox, Chrome, Opera

* Check [Kitchen Sink](kitchensink.html) example (extracted from this file) to see it in action

* Downloads: [jtmpl.js](js/jtmpl.js), [jtmpl.min.js](js/jtmpl.min.js)



Kitchen Sink
------------------------------

```html
<!doctype html>
<html>
<head>
	<link href="css/styles.css">
</head>
<body>
	<h1>Kitchen Sink</h1>
	<p>Demo of all features jtmpl provides</p>
	<a href="#" id="runAutomatedTests">run automated tests</a>
	<div id="view-target"></div>
	<script src="jtmpl.latest.min.js"></script>
	<script>
		var model = {
			dynamicText: 'lowercase',
			array: ['one', 'two', 'three'],
			objArray: [
				{
					f1: 'A_f1',
					f2: 'A_f2'
				},
				{
					f1: 'B_f1',
					f2: 'B_f2'
				}
			],
			field: null,

			checkboxes: {
				fooCheck: true,
				barCheck: false
			},

			// "option 2" will be initially selected
			radioGroupIndex: 1,

			// event handlers
			'#toggleDynamicTextCase:click': function() {
				this.dynamicText = this.dynamicText == 'lowercase' ?
					'UPPERCASE': 'lowercase';
			},
			'#addToArray:click': function() {
				this.array.push(Math.random());
			},
			'#removeLastFromArray:click': function() {
				this.array.pop();
			}
		};

		jtmpl('#view-target', '#view-template', model);
	</script>
	<script id="view-template" type="text/html">
		<h5>model.array</h5>
		<ul>
			{{#array}}
			<li>{{.}}</li>
			{{/array}}
			{{^array}}
			<li>&lt; empty &gt;</li>
			{{/array}}
		</ul>
		<a href="#" id="addToArray">Add random element to model.array</a>
		<a href="#" id="removeLastFromArray">Remove last model.array element</a>

		<h5>model.objArray</h5>
		<ul>
			{{#objArray}}
			<li>{ f1: "<span>{{f1}}</span>", f2: "<span>{{f2}}</span>" }<li>
			{{/objArray}}
			{{^objArray}}
			<li>&lt; empty &gt;</li>
			{{/objArray}}
		</ul>
	
		<a href="#" id="toggleDynamicTextCase">Toggle</a>
		<p>{{dynamicText}}</p>

		<label for="field">Enter something</label> <input id="field" value="{{field}}">
		{{#field}}<p>
			You entered "<span>{{field}}</span>". Delete it and this message will disappear
		</p>{{/field}}

		<h5>model.checkboxes</h5>
		<div>
			{{#checkboxes}}
			<label><input type="checkbox" {{fooCheck}}> fooCheck</label>
			<label><input type="checkbox" {{barCheck}}> barCheck</label>
			{{/checkboxes}}
		</div>

		<h5>model.radioGroupIndex == <span>{{radioGroupIndex}}</span></h5>
		<div>
			<label><input type="radio" name="radio-group" {{radioGroupIndex}}> option 1</label>
			<label><input type="radio" name="radio-group" {{radioGroupIndex}}> option 2</label>
		</div>
	</script>
</body>
</html>
```