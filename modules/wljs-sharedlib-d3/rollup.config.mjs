import nodeResolve from "@rollup/plugin-node-resolve";
import commonjs from '@rollup/plugin-commonjs';
import json from "@rollup/plugin-json";

import terser from '@rollup/plugin-terser';

throw 'do not forget to replace defaultLocale$1 with thinspace for thousausands'

export default {

  input: 'src/kernel.js',
  
  output: [
    {
      file: 'dist/kernel.min.js',
      format: "es",
      strict: false,
      manualChunks: () => 'merged'
    },
    {
      dir: 'dist/',
      format: "es",
      strict: false
    }
  ],
  plugins    : [
  nodeResolve({
    jsnext: true,
    main: false
  }),
  json(),
  commonjs({transformMixedEsModules:true})
  ]
};