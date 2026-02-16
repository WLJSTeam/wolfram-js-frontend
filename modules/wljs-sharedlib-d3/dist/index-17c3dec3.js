function iterate(attrs, path) {
  const keys = Object.keys(attrs), l = keys.length;
  for (let i = 0; i < l; i++){
    const key = keys[i];
    path.attr(key, attrs[key]);
  }
}

function draw(context, attrs, id, scale, refX, refY, d){
  let defs = context.select("defs");
  if (defs.empty()) {
    defs = context.append("defs");
  }

  const path = defs.append("marker")
      .attr("id", id)
      .attr("refX", refX * scale)
      .attr("refY", refY * scale)
      .attr("markerWidth", refX + 2 * scale)
      .attr("markerHeight", refY * 2 * scale)
      .attr("markerUnits", "userSpaceOnUse")
      .attr("orient", "auto-start-reverse")
    .append("path")
      .attr("d", d);

  iterate(attrs, path);
}

function arrow1() {
  let attrs = {
    fill: "black",
    stroke: "black"
  };
  let id = "d3-arrow-1";
  let scale = 1;
  
  function arrow(context){
    draw(
      context,
      attrs,
      id,
      scale,
      15,
      8,
      `M 1 1 Q ${7 * scale} ${5 * scale} ${16 * scale} ${8 * scale} Q ${7 * scale} ${11 * scale} 1 ${15 * scale} L ${4 * scale} ${8 * scale} Z`
    );
  }
  
  arrow.id = function(string){ return arguments.length ? (id = string, arrow) : id; };
  arrow.scale = function(number){ return arguments.length ? (scale = number, arrow) : scale; };
  arrow.attr = function(key, value){ return arguments.length === 2 ? (attrs[key] = value, arrow) : attrs[key]; };
  
  return arrow;
}

function arrow2() {
  let attrs = {
    fill: "black",
    stroke: "black"
  };
  let id = "d3-arrow-2";
  let scale = 1;
  
  function arrow(context){
    draw(
      context,
      attrs,
      id,
      scale,
      17,
      7.5,
      `M 1 1 L ${18 * scale} ${7.5 * scale} L 1 ${14 * scale} L ${5 * scale} ${7.5 * scale} z`
    );
  }
  
  arrow.id = function(string){ return arguments.length ? (id = string, arrow) : id; };
  arrow.scale = function(number){ return arguments.length ? (scale = number, arrow) : scale; };
  arrow.attr = function(key, value){ return arguments.length === 2 ? (attrs[key] = value, arrow) : attrs[key]; };
  
  return arrow;
}

function arrow3() {
  let attrs = {
    fill: "black",
    stroke: "black"
  };
  let id = "d3-arrow-3";
  let scale = 1;
  
  function arrow(context){
    draw(
      context,
      attrs,
      id,
      scale,
      21,
      7,
      `M 1 1 Q ${9 * scale} ${5 * scale} ${22 * scale} ${7 * scale} Q ${9 * scale} ${9 * scale} 1 ${13 * scale} L ${4 * scale} ${7 * scale} Z`
    );
  }
  
  arrow.id = function(string){ return arguments.length ? (id = string, arrow) : id; };
  arrow.scale = function(number){ return arguments.length ? (scale = number, arrow) : scale; };
  arrow.attr = function(key, value){ return arguments.length === 2 ? (attrs[key] = value, arrow) : attrs[key]; };
  
  return arrow;
}

function arrow5() {
  let attrs = {
    fill: "black",
    stroke: "black"
  };
  let id = "d3-arrow-5";
  let scale = 1;
  
  function arrow(context){
    draw(
      context,
      attrs,
      id,
      scale,
      14,
      7,
      `M 1 1 L ${15 * scale} ${7 * scale} L 1 ${13 * scale} L ${3 * scale} ${7 * scale} z`
    );
  }
  
  arrow.id = function(string){ return arguments.length ? (id = string, arrow) : id; };
  arrow.scale = function(number){ return arguments.length ? (scale = number, arrow) : scale; };
  arrow.attr = function(key, value){ return arguments.length === 2 ? (attrs[key] = value, arrow) : attrs[key]; };
  
  return arrow;
}

function arrow10(){
  let attrs = {
    fill: "none",
    stroke: "black",
    "stroke-width": 1
  };
  let id = "d3-arrow-10";
  let scale = 1;
  
  function arrow(context){
    draw(
      context,
      attrs,
      id,
      scale,
      5,
      4.5,
      `M 1 1 L ${5 * scale } ${4.5 * scale} L 1 ${8 * scale}`
    );
  }
  
  arrow.id = function(string){ return arguments.length ? (id = string, arrow) : id; };
  arrow.scale = function(number){ return arguments.length ? (scale = number, arrow) : scale; };
  arrow.attr = function(key, value){ return arguments.length === 2 ? (attrs[key] = value, arrow) : attrs[key]; };
  
  return arrow;
}

function arrow11() {
  let attrs = {
    fill: "none",
    stroke: "black",
    "stroke-width": 1
  };
  let id = "d3-arrow-11";
  let scale = 1;
  
  function arrow(context){
    draw(
      context,
      attrs,
      id,
      scale,
      8,
      8,
      `M 1 1 L ${8 * scale} ${8 * scale} L 1 ${15 * scale}`
    );
  }
  
  arrow.id = function(string){ return arguments.length ? (id = string, arrow) : id; };
  arrow.scale = function(number){ return arguments.length ? (scale = number, arrow) : scale; };
  arrow.attr = function(key, value){ return arguments.length === 2 ? (attrs[key] = value, arrow) : attrs[key]; };
  
  return arrow;
}

function arrow13() {
  let attrs = {
    fill: "none",
    stroke: "black",
    "stroke-width": 1
  };
  let id = "d3-arrow-13";
  let scale = 1;
  
  function arrow(context){
    draw(
      context,
      attrs,
      id,
      scale,
      13,
      10,
      `M 1 1 L ${13 * scale} ${10 * scale} L 1 ${19 * scale}`
    );
  }
  
  arrow.id = function(string){ return arguments.length ? (id = string, arrow) : id; };
  arrow.scale = function(number){ return arguments.length ? (scale = number, arrow) : scale; };
  arrow.attr = function(key, value){ return arguments.length === 2 ? (attrs[key] = value, arrow) : attrs[key]; };
  
  return arrow;
}

export { arrow1, arrow10, arrow11, arrow13, arrow2, arrow3, arrow5 };
