import { draw } from "./utils/draw";

export default function arrow2() {
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
  
  arrow.id = function(string){ return arguments.length ? (id = string, arrow) : id; }
  arrow.scale = function(number){ return arguments.length ? (scale = number, arrow) : scale; }
  arrow.attr = function(key, value){ return arguments.length === 2 ? (attrs[key] = value, arrow) : attrs[key]; }
  
  return arrow;
}