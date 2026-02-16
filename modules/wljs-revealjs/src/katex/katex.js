/**
 * A plugin which enables rendering of math equations inside
 * of reveal.js slides. Essentially a thin wrapper for KaTeX.
 *
 * @author Hakim El Hattab
 * @author Gerhard Burger
 */

let renderMathInElement;

import { svgPathProperties } from "svg-path-properties";

/**
 * A plugin MJP enables Manim-like animation and acts as a post-processor
 * 
 * https://www.cianlm.dev/
 *
 * @author Cian Luke Martin
 */

function MJP(stdout) {
    let id_and_length  = []
    
	
    stdout = stdout.replaceAll(/fill="(.+?)"/g, (m , c) => m + ` color="${c}"`)
    // Get rid of stroke-width="0" stuff
    stdout = stdout.replaceAll(/stroke-width=".+?"/g,"")
    // Remove empty paths
    stdout = stdout.replaceAll('d=""','d="M 0 0"')
    // Rename data-c to id
    stdout = stdout.replaceAll("data-c","id")
    // Make all ids unique by prepending a random string
    stdout = stdout.replaceAll(/use id="(.+?)"/g, (match , id) => {
        const rand_id = Math.random().toString(36).slice(2)
        // stdout.replace(`href="#${id}"`,`href="#${id}_${rand_id}"`)
        return `use id="${id}_${rand_id}"`
    })
    // Collect total lengths
    // Make sure to use non-greedy regex. (.+?) is grabbing too much.
    stdout.replaceAll(/id="(.+?)" d="(.+?)"/g, (match, id , svg_path) => {
        try {
            // console.info(svg_path)
            const properties = new svgPathProperties(svg_path);
            const length =  properties.getTotalLength()
            // console.log(`Path String/Total Length: ${match.length}/${length}`)
            id_and_length.push([id, length])
            return match 
        } catch(e) {
            console.error(`Error: ${e}`)
            // id_and_length.push([id, 0])
            console.warn(svg_path)
            return match
        }
    })
    // console.log(id_and_length)
    // Add total lengths to the corresponding <use> tags with the same id
    for (let i = 0; i < id_and_length.length; i++) {
        const id = id_and_length[i][0]
        const length = id_and_length[i][1]
        stdout = stdout.replaceAll(new RegExp(`<path id="${id}"`,'g'), (match) => {
            return match + ` style="color : inherit" stroke-dasharray="${length}" stroke-dashoffset="${length}"`
        })
    }
          return stdout
}

function DrawSVG(svg, gradient, slide, delay_inc, base_delay, slide_duration) {
    if (slide === void 0) { slide = false; }
    if (delay_inc === void 0) { delay_inc = 0.2; }
    if (base_delay === void 0) { base_delay = 0; }
    if (slide_duration === void 0) { slide_duration = 5; }
    // console.log(tex)
    var box_counter = 0;
    var box_fix = svg.replaceAll(/(<rect )(.+?\/rect>)/g, function (match, g1, g2) {
        // console.log('box_counter='+box_counter)
        box_counter++;
        var rand_id = Math.random().toString(36).slice(2);
        return "<defs>" + g1 + ("id=\"box_counter" + box_counter + "_" + rand_id + "\" ") + g2 + "</defs>" +
            ("<use stroke=\"none\" fill=\"currentColor\" href=\"#box_counter" + box_counter + "_" + rand_id + "\"></use>");
    });
    var stroke_fix = box_fix.replaceAll('<g', '<g stroke="currentColor"');
    // Gradients
    var gradient_svg = stroke_fix;
    // console.log(gradient.length)
    if (gradient.length != 0) {
        // @ts-ignore
        var viewBox_1 = gradient_svg.match(/viewBox="(.+?)"/)[1].split(' ')[1];
        // console.log(viewBox)
        var rand_id_1 = Math.random().toString(36).slice(2);
        // regex for <svg ...> is /<svg[^>]*>/
        // explanation: [^>]* means any character except >, repeated 0 or more times
        if (slide) {
            gradient_svg = slide_gradient(rand_id_1, viewBox_1, gradient_svg, gradient, slide_duration);
        }
        else {
            gradient_svg = gradient_svg.replace(/<svg[^>]*>/, function (match) {
                var linear_gradient = "\n                    <linearGradient id=\"gradient" + rand_id_1 + "\" x1=\"0%\" y1=\"50%\" x2=\"100%\" y2=\"50%\">\n                    " + gradient.map(function (color, index) {
                    return "<stop offset=\"" + Math.round(100 * index / (gradient.length - 1)) + "%\" stop-color=\"" + color + "\"></stop>";
                }).join('') + "\n                </linearGradient>";
                var rect = "<rect id=\"rect" + rand_id_1 + "\" x=\"-5%\" y=\"" + viewBox_1 * 1.1 + "\" width=\"110%\" height=\"120%\" fill=\"url(#gradient" + rand_id_1 + ")\" />";
                return match + "<defs>" + linear_gradient + rect + "</defs>";
            });
        }
        gradient_svg = gradient_svg.replace("</defs>", function (match) {
            return match + ("<mask id=\"mask" + rand_id_1 + "\">");
        });
        gradient_svg = gradient_svg.replace("</svg>", function (match) {
            return "</mask>" + ("<use href=\"#rect" + rand_id_1 + "\" mask=\"url(#mask" + rand_id_1 + ")\" />") + match;
        });
    }

    var path_style = gradient_svg.replaceAll(/<path /g, function (match) {
        delay += delay_inc;
        return match + ("style=\"" + (gradient.length ? 'color : white' : '') + "; stroke-width: 20px; fill: none;\n animation: inherit\"");
    });

    var delay = -delay_inc + base_delay;
    var animated = path_style.replaceAll(/<use /g, function (match) {
        delay += delay_inc;
        return match + ("style=\"" + (gradient.length ? 'color : white' : '') + "; stroke-width: 20px; fill: none;\n        animation: 2s ease " + delay + "s 1 normal forwards running line-anim,\n        2s ease " + (1 + delay) + "s 1 normal forwards running fill;\"");
    });
    return animated;
}

function slide_gradient(rand_id, viewBox, str, gradient, duration) {
    return str.replace(/<svg[^>]*>/, function (match) {
        // 0 => -100, 0, 100, 1 => -50, 50,
        // 0 => -100, 0, 100, 1=> -75, 25, 2=> -50, 50, 3=> -25, 75
        var percent = function (index) { return Math.round(100 * index / (gradient.length - 1)) / 2; };
        var slide_gradient = "\n        <linearGradient id=\"gradient" + rand_id + "\" x1=\"0%\" y1=\"50%\" x2=\"100%\" y2=\"50%\">\n        " + (gradient.map(function (color, index) {
            return "<stop offset=\"" + (percent(index) - 100) + "%\" stop-color=\"" + color + "\">\n                <animate attributeName=\"offset\" dur=\"" + duration + "s\" repeatCount=\"indefinite\" values=\"" + (percent(index) - 100) + "%;" + percent(index) + "%\"></animate>\n            </stop>";
        }).join('') + gradient.map(function (color, index) {
            return "<stop offset=\"" + percent(index) + "%\" stop-color=\"" + color + "\">\n                    <animate attributeName=\"offset\" dur=\"" + duration + "s\" repeatCount=\"indefinite\" values=\"" + percent(index) + "%;" + (percent(index) + 100) + "%\"></animate>\n                </stop>";
        }).join('') +
            ("<stop offset=\"" + 100 + "%\" stop-color=\"" + gradient[0] + "\">\n                    <animate attributeName=\"offset\" dur=\"" + duration + "s\" repeatCount=\"indefinite\" values=\"" + 100 + "%;" + 200 + "%\"></animate>\n                </stop>")) + " </linearGradient>";
        var rect = "<rect id=\"rect" + rand_id + "\" x=\"-5%\" y=\"" + viewBox * 1.1 + "\" width=\"110%\" height=\"120%\" fill=\"url(#gradient" + rand_id + ")\" />";
        return match + "<defs>" + slide_gradient + rect + "</defs>";
    });
}

const extractOpts = (parent) => {
	return [
		parent.dataset.eqGradient ? JSON.parse(parent.dataset.eqGradient.replaceAll("'", '"')) : [],
		parent.dataset.eqColorPrecess == "true",
		parent.dataset.eqSpeed ? parseFloat(parent.dataset.eqSpeed) : 0.3,
		parent.dataset.eqDelay ? parseFloat(parent.dataset.eqDelay) : 0,
		parent.dataset.eqPrecessPeriod ? parseFloat(parent.dataset.eqPrecessPeriod) : 5
	]
}

const applyAnimation = (svg, span, opts) => {
	const processed = DrawSVG(MJP(svg),
		...opts
	);

	span.innerHTML = processed;
	span.firstChild.classList.add('mt-6', 'mb-6', 'ml-auto', 'mr-auto');
}

const applyPlaceholder = (svg, span, opts) => {
	span.innerHTML = svg;
	span.firstChild.classList.add('mt-6', 'mb-6', 'ml-auto', 'mr-auto', 'opacity-0');
}

let JaxLoaded = false;

const manimTags = {'eqStatic': false,  'eqSpeed':0.3, 'eqGradient':[], 'eqColorPrecess':false, 'eqDelay':0}

export const KaTeX = () => {
	let deck;



	let defaultOptions = {
		version: 'latest',
		delimiters: [
			{left: '$$', right: '$$', display: true}, // Note: $$ has to come before $
			{left: '$', right: '$', display: false},
			{left: '\\(', right: '\\)', display: false},
			{left: '\\[', right: '\\]', display: true}
		],
		ignoredTags: ['script', 'noscript', 'style', 'textarea', 'pre'],
		customRenderer: (math, span, fragment, opts, parent) => {
			const o = {};
    		o.display = true;
			//console.log('Process EQ');
			//console.log(window.MathJax);
			if (!window.MathJax) return false;

			const dataset = Object.keys(parent.dataset);
			console.log(dataset);
			
			if (!(Object.keys(manimTags).some(v => dataset.includes(v)))) return false;

			const svg = MathJax.tex2svg(math.data, o);
			const svg_content = svg.innerHTML;
			svg.remove();

			if (parent.dataset.eqStatic) {
				span.innerHTML = svg_content;
				span.firstChild.classList.add('mt-6', 'mb-6', 'ml-auto', 'mr-auto');
				fragment.appendChild(span);
				return true;
			}

			const options = extractOpts(parent);

			if (dataset.includes('fragmentIndex')) {
				applyPlaceholder(svg_content, span, options);
				const fragmentIndex = parseInt(parent.dataset.fragmentIndex);

				let previousSlide = false;

				deck.on( 'slidechanged', event => {
					// event.previousSlide, event.currentSlide, event.indexh, event.indexv
					const slide = event.indexh;
					console.log(slide);
					if (event.previousSlide == event.currentSlide) return;
			
					if (previousSlide !== false) {
					  applyPlaceholder(svg_content, span, options);
					  previousSlide = false;
					}
			
					/*if (event.currentSlide.contains(span)) { //Horribly slow!!!
						applyAnimation(svg_content, span, options);
					}*/
			
				  } );
			
				  deck.on( 'fragmentshown', (event) => {
					const state = deck.getState();
			   
					
					if (event.fragment == parent) { 
						console.log(parent);
						console.log('animate tex!');
						applyAnimation(svg_content, span, options);
					}

					//if (Object.keys(events).includes(String(state.indexh))) {
					 // fragmentFire(state.indexh, state.indexf);
					//}
				  } );			

			} else {
				let previousSlide = false;

				if (deck.getCurrentSlide().contains(parent)) { //Horribly slow!!!
					console.log('Early bird!');
					applyAnimation(svg_content, span, options);
				}

				deck.on( 'slidechanged', event => {
					// event.previousSlide, event.currentSlide, event.indexh, event.indexv
					const slide = event.indexh;
					console.log(slide);
					if (event.previousSlide == event.currentSlide) return;
			
					if (previousSlide !== false) {
					  applyPlaceholder(svg_content, span, options);
					  previousSlide = false;
					}
			
					if (event.currentSlide.contains(parent)) { //Horribly slow!!!
						applyAnimation(svg_content, span, options);
					}
			
				  } );		

				//applyAnimation(svg_content, span, options);
			}


			
    		
			fragment.appendChild(span);
			
			return true;
		}
		/*postRender: (element) => {
			console.log(DrawSVG(element.innerHTML, [], true, 0.2, 0.2));

			return element;
		}*/
	}

	const loadCss = src => {
		let link = document.createElement('link');
		link.rel = 'stylesheet';
		link.href = src;
		document.head.appendChild(link);
	};

	/**
	 * Loads a JavaScript file and returns a Promise for when it is loaded
	 * Credits: https://aaronsmith.online/easily-load-an-external-script-using-javascript/
	 */

	return {
		id: 'katex',

		init: function (reveal) {

			deck = reveal;

			let revealOptions = deck.getConfig().katex || {};

			let options = {...defaultOptions, ...revealOptions};
			const {local, version, extensions, ...katexOptions} = options;


			const renderMath = () => {
				const el = reveal.getSlidesElement();
				console.warn(el);
				renderMathInElement(el, defaultOptions);
				deck.layout();
			}

			//loadCss(cssUrl);

			// For some reason dynamically loading with defer attribute doesn't result in the expected behavior, the below code does
			if (!renderMathInElement) {
				window.interpretate.shared.katex.load().then(() => {
					renderMathInElement = window.interpretate.shared.katex.autorender;
					console.log(renderMathInElement);

					if( deck.isReady() ) {
						renderMath();
					}
					else {
						deck.on( 'ready', renderMath.bind( this ) );
					}
				})
			} else {
				renderMathInElement = window.interpretate.shared.katex.autorender;
				console.log(renderMathInElement);

				if( deck.isReady() ) {
					renderMath();
				}
				else {
					deck.on( 'ready', renderMath.bind( this ) );
				}
			}
			//if (!d3) d3 = interpretate.shared.d3.d3;

		}
	}

};
