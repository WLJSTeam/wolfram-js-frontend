import { aI as _, aJ as Color } from './mermaid.core-a67b2830.js';

/* IMPORT */
/* MAIN */
const channel = (color, channel) => {
    return _.lang.round(Color.parse(color)[channel]);
};
/* EXPORT */
var channel$1 = channel;

export { channel$1 as c };
