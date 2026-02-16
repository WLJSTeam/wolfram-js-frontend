import { draw } from "./utils/draw";

export default function arrow1(offset=0) {
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
      `M 1 1 Q ${7 * scale} ${5 * scale} ${16 * scale} ${8 * scale} Q ${7 * scale} ${11 * scale} 1 ${15 * scale} L ${4 * scale} ${8 * scale} Z`,
      offset
    );
  }
  
  arrow.id = function(string){ return arguments.length ? (id = string, arrow) : id; }
  arrow.scale = function(number){ return arguments.length ? (scale = number, arrow) : scale; }
  arrow.attr = function(key, value){ return arguments.length === 2 ? (attrs[key] = value, arrow) : attrs[key]; }
  
  return arrow;
}