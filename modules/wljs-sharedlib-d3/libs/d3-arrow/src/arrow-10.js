import { draw } from "./utils/draw";

export default function arrow10(){
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
  
  arrow.id = function(string){ return arguments.length ? (id = string, arrow) : id; }
  arrow.scale = function(number){ return arguments.length ? (scale = number, arrow) : scale; }
  arrow.attr = function(key, value){ return arguments.length === 2 ? (attrs[key] = value, arrow) : attrs[key]; }
  
  return arrow;
}