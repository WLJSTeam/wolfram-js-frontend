core['CoffeeLiqueur`Extensions`ExportImport`DynamicAnalyzer`Sniffer'] = async (args, env) => {
    const type = await interpretate(args[0], env);
    return await core['CoffeeLiqueur`Extensions`ExportImport`DynamicAnalyzer`Sniffer'][type](args.slice(1), env);
}

core['CoffeeLiqueur`Extensions`ExportImport`DynamicAnalyzer`Sniffer'].Inject = async (args, env) => {
    console.warn('Injecting a sniffer');
    server.kernel.io.__headSymbol = server.kernel.io.headSymbol;
    server.kernel.io.headSymbol = 'Internal`Kernel`CaptureEventFunction';
    return true;
}

core['CoffeeLiqueur`Extensions`ExportImport`DynamicAnalyzer`Sniffer'].Eject = async (args, env) => {
    console.warn('Eject a sniffer');
    server.kernel.io.headSymbol = server.kernel.io.__headSymbol;
    return true;
}

core['CoffeeLiqueur`Extensions`ExportImport`DynamicAnalyzer`Sniffer'].Retrack = async (args, env) => {
    console.warn('Retracking symbols...');
    console.log(Object.keys(server.kernel.trackedSymbols));
    Object.keys(server.kernel.trackedSymbols).forEach((sym) => server.kernel.addTracker(sym));
    return true;
}

core['CoffeeLiqueur`Extensions`ExportImport`DynamicAnalyzer`Sniffer'].Confirm = async (args, env) => {
    const secret = await interpretate(args[0], env);
    await server.kernel.io.fetch(secret);
    return true;
}

let cryptoHash = async (message) => {
    const msgUint8 = new TextEncoder().encode(message); // encode as (utf-8) Uint8Array
    const hashBuffer = await window.crypto.subtle.digest("SHA-1", msgUint8); // hash the message
    const hashArray = Array.from(new Uint8Array(hashBuffer)); // convert buffer to byte array
    const hashHex = hashArray
      .map((b) => b.toString(16).padStart(2, "0"))
      .join(""); // convert bytes to hex string
    return hashHex;
}

if (!(window?.crypto?.subtle)) {
    cryptoHash = async () => {
        interpretate.alert('Crypto features are not available in non-secured context. Please run an app locally or use reverse proxy with TSL.');
        throw 'Crypto features are not available in non-secured context';
    }
}

core['CoffeeLiqueur`Extensions`ExportImport`BlackBox`PavlovMachine`Private`CalculateHash'] = async (args, env) => {
    const states = await interpretate(args[0], env);
    const res = [];
    for (const p of states) {
        const hash = await cryptoHash(JSON.stringify(p));
        res.push(hash);
    }

    return res;
}

core['CoffeeLiqueur`Extensions`ExportImport`BlackBox`AnimationMachine`Private`CalculateHash'] = core['CoffeeLiqueur`Extensions`ExportImport`BlackBox`PavlovMachine`Private`CalculateHash'];

const delay = (ms) => new Promise(resolve => setTimeout(resolve, ms))


core['CoffeeLiqueur`Extensions`ExportImport`Slides`Private`LoadPDFLibrary'] = async (args, env) => {
    await import('./../dist/slides.js');
    return true;
}

core['CoffeeLiqueur`Extensions`ExportImport`Slides`Private`ShakeSlide'] = async (args, env) => {
    const deck = Object.values(SupportedCells['slide'].context.decks)[0];
    deck.layout();
    return 0;
}

core['CoffeeLiqueur`Extensions`ExportImport`Slides`Private`CheckElectron'] = async (args, env) => {
    if (window.electronAPI) return true;
    return false;
}

core['CoffeeLiqueur`Extensions`ExportImport`Slides`Private`GetNextSlide'] = async (args, env) => {
    const d = await interpretate(args[0], env);
    const deck = Object.values(SupportedCells['slide'].context.decks)[0];
    const res = (deck.getState().indexh + 1 < deck.getTotalSlides());
    
    deck.navigateNext(1);
    await delay(d);
    return res;
}


core['CoffeeLiqueur`Extensions`ExportImport`BlackBox`StateMachine`Private`SubmitState'] = async (args, env) => {
    const state = await interpretate(args[0], env);
    const events = await interpretate(args[1], env);
    const secret = await interpretate(args[2], env);

    const options = await core._getRules(args, env);
    let pause = 33;
    if (options.Delay) pause = options.Delay;

    

    console.warn({state, events, secret});

    const hash = await cryptoHash(JSON.stringify(state));


    let index = 0;
    for (const s of state) {
        server.kernel.io.fire(events[index][0], s, events[index][1]);
        index++;
        await delay(pause);
    }

    await server.kernel.io.fetch(secret);
    return hash;
}

core['CoffeeLiqueur`Extensions`ExportImport`Internal`renderMarkdownToString'] = async (args, env) => {
    const input = await interpretate(args[0], env);
    return await window.SupportedCells['markdown'].view.renderToHTML(input);
}

core['CoffeeLiqueur`Extensions`ExportImport`BlackBox`WidgetStateMachine`Private`SubmitState'] = core['CoffeeLiqueur`Extensions`ExportImport`BlackBox`StateMachine`Private`SubmitState'] 