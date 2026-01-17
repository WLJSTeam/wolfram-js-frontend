import { draw } from "./utils/draw";

export default function arrow13() {
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
  
  arrow.id = function(string){ return arguments.length ? (id = string, arrow) : id; }
  arrow.scale = function(number){ return arguments.length ? (scale = number, arrow) : scale; }
  arrow.attr = function(key, value){ return arguments.length === 2 ? (attrs[key] = value, arrow) : attrs[key]; }
  
  return arrow;
}