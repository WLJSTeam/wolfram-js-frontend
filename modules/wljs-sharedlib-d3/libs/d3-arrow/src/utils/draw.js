import { iterate } from "./iterate";

export function draw(context, attrs, id, scale, refX, refY, d, offset=0){
  let defs = context.select("defs");
  if (defs.empty()) {
    defs = context.append("defs");
  }

  const path = defs.append("marker")
      .attr("id", id)
      .attr("refX", refX * scale + offset)
      .attr("refY", refY * scale)
      .attr("markerWidth", refX * 2 * scale)
      .attr("markerHeight", refY * 2 * scale)
      .attr("markerUnits", "userSpaceOnUse")
      .attr("orient", "auto-start-reverse")
    .append("path")
      .attr("d", d);

  iterate(attrs, path);
}