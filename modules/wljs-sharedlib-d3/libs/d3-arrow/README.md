# d3-arrow
Attach arrowheads to SVG elements. This module is in alpha, so use with caution.

## Installing

If you use NPM, `npm install d3-arrow`. Otherwise, download the [latest release](https://github.com/HarryStevens/d3-arrow/raw/master/dist/d3-arrow.zip). AMD, CommonJS, and vanilla environments are supported. In vanilla, a d3 global is exported:

```html
<script src="https://unpkg.com/d3-arrow@0.0.25/dist/d3-arrow.min.js"></script>
<script>

const arrow = d3.arrow1();

</script>
```

## API Reference

The API is based on the list of arrows in Adobe Illustrator v24.1.2. To add an arrowhead to an SVG element, you must first add the arrowhead generator to your SVG using [<i>selection</i>.call](https://github.com/d3/d3-selection#selection_call). Then, pass the generator's [<i>id</i>](#arrow_id) to the element's "marker-end" attribute:

```js
const svg = d3.select("body").append("svg")
    .attr("width", 60)
    .attr("height", 20);

const arrow = d3.arrow1()
    .id("my-arrow")
    .attr("fill", "steelblue")
    .attr("stroke", "steelblue");

svg.call(arrow);

svg.append("polyline")
    .attr("marker-end", "url(#my-arrow)")
    .attr("points", [[5, 10], [55, 10]])
    .attr("stroke", "steelblue")
    .attr("stroke-width", 2);
```

<a name="arrow1" href="#arrow1">#</a> d3.<b>arrow1</b>() · [Source](https://github.com/harrystevens/d3-arrow/blob/master/src/arrow-1.js "Source"), [Example](https://observablehq.com/d/7759e56ba89ced03 "Example")

Creates a new arrow generator with an [<i>id</i>](#arrow_id) of "d3-arrow-1" and a [<i>scale</i>](#arrow_scale) of 1.

<a name="arrow2" href="#arrow2">#</a> d3.<b>arrow2</b>() · [Source](https://github.com/harrystevens/d3-arrow/blob/master/src/arrow-2.js "Source"), [Example](https://observablehq.com/d/7759e56ba89ced03 "Example")

Creates a new arrow generator with an [<i>id</i>](#arrow_id) of "d3-arrow-2" and a [<i>scale</i>](#arrow_scale) of 1.

<a name="arrow3" href="#arrow3">#</a> d3.<b>arrow3</b>() · [Source](https://github.com/harrystevens/d3-arrow/blob/master/src/arrow-3.js "Source"), [Example](https://observablehq.com/d/7759e56ba89ced03 "Example")

Creates a new arrow generator with an [<i>id</i>](#arrow_id) of "d3-arrow-3" and a [<i>scale</i>](#arrow_scale) of 1.

<a name="arrow5" href="#arrow5">#</a> d3.<b>arrow5</b>() · [Source](https://github.com/harrystevens/d3-arrow/blob/master/src/arrow-5.js "Source"), [Example](https://observablehq.com/d/7759e56ba89ced03 "Example")

Creates a new arrow generator with an [<i>id</i>](#arrow_id) of "d3-arrow-5" and a [<i>scale</i>](#arrow_scale) of 1.

<a name="arrow10" href="#arrow10">#</a> d3.<b>arrow10</b>() · [Source](https://github.com/harrystevens/d3-arrow/blob/master/src/arrow-10.js "Source"), [Example](https://observablehq.com/d/7759e56ba89ced03 "Example")

Creates a new arrow generator with an [<i>id</i>](#arrow_id) of "d3-arrow-10" and a [<i>scale</i>](#arrow_scale) of 1.

<a name="arrow11" href="#arrow11">#</a> d3.<b>arrow11</b>() · [Source](https://github.com/harrystevens/d3-arrow/blob/master/src/arrow-11.js "Source"), [Example](https://observablehq.com/d/7759e56ba89ced03 "Example")

Creates a new arrow generator with an [<i>id</i>](#arrow_id) of "d3-arrow-11" and a [<i>scale</i>](#arrow_scale) of 1.

<a name="arrow13" href="#arrow13">#</a> d3.<b>arrow13</b>() · [Source](https://github.com/harrystevens/d3-arrow/blob/master/src/arrow-13.js "Source"), [Example](https://observablehq.com/d/7759e56ba89ced03 "Example")

Creates a new arrow generator with an [<i>id</i>](#arrow_id) of "d3-arrow-13" and a [<i>scale</i>](#arrow_scale) of 1.

<a name="_arrow" href="#_arrow">#</a> <i>arrow</i>(<i>context</i>) · [Source](https://github.com/d3/d3-arrow/blob/master/src/index.js), [Example](https://observablehq.com/d/7759e56ba89ced03 "Example")

Add the arrow generator to the given <i>context</i>, which should be a selection of SVG elements.

<a name="arrow_id" href="#arrow_id">#</a> <i>arrow</i>.id([<i>id</i>]) · [Source](https://github.com/d3/d3-arrow/blob/master/src/index.js), [Example](https://observablehq.com/d/7759e56ba89ced03 "Example")

Sets or gets the arrow's unique <i>id</i> string, which you'll reference when setting the element's "marker-end" attribute.

<a name="arrow_scale" href="#arrow_scale">#</a> <i>arrow</i>.scale([<i>scale</i>]) · [Source](https://github.com/d3/d3-arrow/blob/master/src/index.js), [Example](https://observablehq.com/d/7759e56ba89ced03 "Example")

Sets or gets the arrow's <i>scale</i> number.

<a name="arrow_attr" href="#arrow_attr">#</a> <i>arrow</i>.attr(<i>key</i>[, <i>value</i>]) · [Source](https://github.com/d3/d3-arrow/blob/master/src/utils/iterate.js), [Example](https://observablehq.com/d/7759e56ba89ced03 "Example")

Sets or gets an appearance attribute's value.