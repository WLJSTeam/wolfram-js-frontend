import babel from "rollup-plugin-babel";

export default {
  input: "index.js",
  output: {
    extend: true,
    file: "dist/d3-arrow.js",
    format: "umd",
    name: "d3"
  },
  plugins: [
    babel({
      exclude: 'node_modules/**'
    })
  ]
}