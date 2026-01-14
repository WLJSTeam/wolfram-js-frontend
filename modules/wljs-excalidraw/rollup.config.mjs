import nodeResolve from "@rollup/plugin-node-resolve";
import commonjs from '@rollup/plugin-commonjs';
import json from "@rollup/plugin-json";
import replace from 'rollup-plugin-replace';
import terser from '@rollup/plugin-terser';

export default {

  input: 'src/kernel.js',
  
  output: [
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
  replace({
    'process.env.NODE_ENV': JSON.stringify( 'production' ),
    'process.env.IS_PREACT': JSON.stringify( 'false' )
  }),
  commonjs({transformMixedEsModules:true})
  ]
};