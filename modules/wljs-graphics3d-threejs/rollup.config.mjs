import nodeResolve from "@rollup/plugin-node-resolve";
import commonjs from '@rollup/plugin-commonjs';
import json from "@rollup/plugin-json";

import serve from "rollup-plugin-serve";

import terser from '@rollup/plugin-terser';

export default {

  input: 'src/kernel.js',
  
  output: [
    {
      file: 'dist/kernel.min.js',
      format: "es",
      strict: false,
      manualChunks: () => 'merged',
      plugins: [terser()]
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
  commonjs({transformMixedEsModules:true}),
  /*serve({
    // Launch in browser (default: false)
    open: true,
  
    // Page to navigate to when opening the browser.
    // Will not do anything if open=false.
    // Remember to start with a slash.
    openPage: '_gallery.html',
  
    // Show server address in console (default: true)
    verbose: true,
  
    // Multiple folders to serve from
    contentBase: ['dist', 'tests/public', 'tests/Packages', 'assets'],
  
    // Options used in setting up server
    host: 'localhost',
    port: 10001,

  
    // execute function after server has begun listening
    onListening: function (server) {
      const address = server.address()
      const host = address.address === '::' ? 'localhost' : address.address
      // by using a bound function, we can access options as `this`
      const protocol = this.https ? 'https' : 'http'
      console.log(`Server listening at ${protocol}://localhost:${address.port}/`)
    }
  })*/
  ]
};