const plugin = require('tailwindcss/plugin')
const platforms = [['Browser', 'bro']]

/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './../../**/*.wlx',
    './../wljs-inputs/src/kernel.js'
  ],
  theme: {
    extend: {
      // ...
    },
  },
  plugins: [
    require('@tailwindcss/typography'),
    require('@tailwindcss/forms'),
    require('@tailwindcss/aspect-ratio'),
    require('@tailwindcss/container-queries'),    
    plugin(({ addVariant }) => {
      platforms.forEach((platform) => {
        addVariant(`${platform[1]}`, `[os="${platform[0]}"] &`)
      })
    }),
  ],
  safelist: [
    'text-2xl',
    'text-3xl',
    'bg-teal-400',
    'bg-teal-300',
    'hover:bg-teal-400',
    {
      pattern: /columns-.*/,
    }     
  ]  
}
