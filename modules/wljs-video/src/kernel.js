core['CoffeeLiqueur`Extensions`Video`Internal`guiBox'] = async (args, env) => {
    const uid = uuidv4();
    

    const opts = await core._getRules(args, env);

    const length = opts.FullLength * 60.0;
    env.local.duration = length;

    const additionalInfo = "Data is on Kernel";

    let playClass = '', stopClass = 'hidden';

    env.element.classList.add(...('sm-controls cursor-default rounded-md 0 py-1 px-2 bg-gray-100 text-left text-gray-500 ring-1 ring-inset ring-gray-400 text-xs flex flex-col'.split(' ')));
    env.element.style.verticalAlign = "middle";
    env.element.innerHTML = `<div class="flex flex-col items-center text-center">
    <div class="mx-1 my-1 rounded overflow-hidden p-0" id="${uid}-screen"></div>
    <div class="flex-row flex items-center"><svg class="w-4 h-4 text-gray-500 inline-block mt-auto mb-auto" viewBox="0 0 24 24" fill="none">
<path class="group-hover:opacity-0" d="M3 11V13M6 10V14M9 11V13M12 9
V15M15 6V18M18 10V14M21 11V13" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
<path d="M3 11V13M6 8V16M9 10V14M12 7V17M15 4V20M18 9V15M21 11V13" class="opacity-0 group-hover:opacity-100" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
</svg> <button id="${uid}-stop" class="px-1 ${stopClass}"><svg fill="currentColor" class="w-3 h-3" viewBox="0 0 256 256"> <path d="M48.227 65.473c0-9.183 7.096-16.997 16.762-17.51 9.666-.513 116.887-.487 125.094-.487 8.207 0 17.917 9.212 17.917 17.71 0 8.499.98 117.936.49 126.609-.49 8.673-9.635 15.995-17.011 15.995-7.377 0-117.127-.327-126.341-.327-9.214 0-17.472-7.793-17.192-16.1.28-8.306.28-116.708.28-125.89zm15.951 4.684c-.153 3.953 0 112.665 0 116.19 0 3.524 3.115 5.959 7.236 6.156 4.12.198 112.165.288 114.852 0 2.686-.287 5.811-2.073 5.932-5.456.12-3.383-.609-113.865-.609-116.89 0-3.025-3.358-5.84-6.02-5.924-2.662-.085-110.503 0-114.155 0-3.652 0-7.083 1.972-7.236 5.924z" fill-rule="evenodd"/>
</svg></button>
<button id="${uid}-play" class="px-1 ${playClass}"><svg fill="currentColor" class="w-3 h-3" viewBox="0 0 24 24"><path d="M16.6582 9.28638C18.098 10.1862 18.8178 10.6361 19.0647 11.2122C19.2803 11.7152 19.2803 12.2847 19.0647 12.7878C18.8178 13.3638 18.098 13.8137 16.6582 14.7136L9.896 18.94C8.29805 19.9387 7.49907 20.4381 6.83973 20.385C6.26501 20.3388 5.73818 20.0469 5.3944 19.584C5 19.053 5 18.1108 5 16.2264V7.77357C5 5.88919 5 4.94701 5.3944 4.41598C5.73818 3.9531 6.26501 3.66111 6.83973 3.6149C7.49907 3.5619 8.29805 4.06126 9.896 5.05998L16.6582 9.28638Z" stroke="currentColor" stroke-width="2" stroke-linejoin="round"/></svg></button><div id="${uid}-bar" style="width:10rem" class="h-2 ring ring-1 ring-gray-400"><div style="width:0%" class="h-2 bg-sys"></div></div><span id="${uid}-text" class="leading-normal pl-1">${(length || 1.0).toFixed(2)} sec</span></div><div class="text-xs text-gray-400">${additionalInfo}</div></div>`;

    const screen = document.getElementById(uid+'-screen');
    const playButton = document.getElementById(uid+'-play');
    const stopButton = document.getElementById(uid+'-stop');
    const bar = document.getElementById(uid+'-bar');
    const pbar = bar.firstChild;

    server.kernel.io.fire(opts.Event, 0.0, 'Set');
    await server.kernel.io.fetch('Now');
 
    bar.addEventListener('click', (ev) => {
        const p = ev.offsetX/bar.clientWidth;
        server.kernel.io.fire(opts.Event, p, 'Set');
        env.local.timeOffset = p * env.local.duration;
        pbar.style.width = Math.round(100 * p) + "%"; 
    });

    env.local.prevState = false;

    playButton.addEventListener('click',  () => {      
        env.local.state(true);
    });

    stopButton.addEventListener('click',  () => {    
        env.local.state(false);        
    });

    const text = document.getElementById(uid + '-text');

    env.local.timeOffset = 0;

    function recalcTime() {
        env.local.timeOffset += 30/1000.0;  
        
        if (env.local.timeOffset >= env.local.duration) {
            env.local.state(false);
            env.local.timeOffset = 0;       
            server.kernel.io.fire(opts.Event, true, 'Pause'); 
            server.kernel.io.fire(opts.Event, 0.0, 'Set'); 
        }
    }

    env.local.prevState = false;

    
    env.local.state = async (state = false) => {
        if (env.local.prevState == state) return;

        if (state) {
            text.innerText = 'Playing';

            server.kernel.io.fire(opts.Event, true, 'Resume');
            await server.kernel.io.fetch('Now'); 

            env.local.state.timer = setInterval(() => {
                const time = env.local.timeOffset;
                if (time >= env.local.duration) return;
                pbar.style.width = Math.round(100 * time / env.local.duration) + "%";        
            }, 50);
            playButton.classList.add('hidden');
            stopButton.classList.remove('hidden');

            
            env.local.ticker = setInterval(recalcTime, 30);

        } else {
            text.innerText = 'Paused';
            if (env.local.state.timer) clearInterval(env.local.state.timer);
            env.local.state.timer = false;
            stopButton.classList.add('hidden');

            server.kernel.io.fire(opts.Event, true, 'Pause');  
            playButton.classList.remove('hidden');  
            if (env.local.ticker) clearInterval(env.local.ticker);
            env.local.ticker = false;
        }

        env.local.prevState = state;
    }     


    interpretate(args[0], {...env, element: screen});
    interpretate(args[1], {...env, element: false});
}

core['CoffeeLiqueur`Extensions`Video`Internal`guiBox'].destroy = (args, env) => {
    if (env.local.ticker) clearInterval(env.local.ticker);
    if (env.local.state.timer) clearInterval(env.local.state.timer);
}

core['CoffeeLiqueur`Extensions`Video`Internal`guiBox'].virtual = true;