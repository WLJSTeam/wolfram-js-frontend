import { p as parser$1, f as flowDb } from './flowDb-c1833063-f36dbad0.js';
import { f as flowRendererV2, g as flowStyles } from './styles-483fbfea-c8df9dd6.js';
import { u as setConfig } from './mermaid.core-a67b2830.js';
import './graph-fdf4911f.js';
import './layout-e33fd557.js';
import './index-01f381cb-bb45b669.js';
import './clone-0b62b503.js';
import './edges-066a5561-2c2faae1.js';
import './createText-ca0c5216-5bee5a67.js';
import './line-73797e89.js';
import './array-72ffbca2.js';
import './path-6ca35b3e.js';
import './channel-133a3032.js';

const diagram = {
  parser: parser$1,
  db: flowDb,
  renderer: flowRendererV2,
  styles: flowStyles,
  init: (cnf) => {
    if (!cnf.flowchart) {
      cnf.flowchart = {};
    }
    cnf.flowchart.arrowMarkerAbsolute = cnf.arrowMarkerAbsolute;
    setConfig({ flowchart: { arrowMarkerAbsolute: cnf.arrowMarkerAbsolute } });
    flowRendererV2.setConf(cnf.flowchart);
    flowDb.clear();
    flowDb.setGen("gen-2");
  }
};

export { diagram };
