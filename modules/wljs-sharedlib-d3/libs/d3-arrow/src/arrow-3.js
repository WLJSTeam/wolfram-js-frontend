import { draw } from "./utils/draw";

export default function arrow3() {
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
  
  arrow.id = function(string){ return arguments.length ? (id = string, arrow) : id; }
  arrow.scale = function(number){ return arguments.length ? (scale = number, arrow) : scale; }
  arrow.attr = function(key, value){ return arguments.length === 2 ? (attrs[key] = value, arrow) : attrs[key]; }
  
  return arrow;
}