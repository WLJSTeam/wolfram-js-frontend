(function (global) {
  if (global.BullParty) return;

  const STYLE_ID = "bp-style";
  const ROOT_ID = "bp-root";

  const DEFAULTS = {
    duration: 5200,
    groundOffset: 80,
    shakeMax: 14,
    rotateMax: 0.8,
    particleRate: 46,
    turboParticles: true,
    zIndex: 2147483647,
    bullScale: 1,
    colorTheme: "sunset",   // "sunset" | "ember" | "midnight"
    direction: "right",     // "right" | "left"
  };

  const prefersReduced =
    typeof window !== "undefined" &&
    window.matchMedia &&
    window.matchMedia("(prefers-reduced-motion: reduce)").matches;

  function injectStyles() {
    if (document.getElementById(STYLE_ID)) return;

    const css = `
#${ROOT_ID}{
  position: fixed;
  inset: 0;
  pointer-events: none;
  z-index: ${DEFAULTS.zIndex};
  overflow: visible;
}
#${ROOT_ID} .bp-layer{
  position: absolute;
  inset: 0;
  overflow: visible;
}
#${ROOT_ID} .bp-bull{
  position: absolute;
  left: 0;
  bottom: 0;
  width: 180px;
  height: 120px;
  transform-origin: 50% 85%;
  filter:
    drop-shadow(0 14px 22px rgba(0,0,0,0.32))
    drop-shadow(0 0 26px rgba(255,160,40,0.16));
  will-change: transform, left, top;
}
#${ROOT_ID} .bp-dust,
#${ROOT_ID} .bp-smoke,
#${ROOT_ID} .bp-spark{
  position: absolute;
  border-radius: 50%;
  pointer-events: none;
  will-change: transform, opacity;
}
#${ROOT_ID} .bp-dust{
  background:
    radial-gradient(circle at 30% 30%, rgba(255,255,255,0.22), transparent 55%),
    radial-gradient(circle at 70% 70%, rgba(255,180,80,0.14), transparent 60%),
    rgba(255,255,255,0.06);
  filter: blur(0.2px);
}
#${ROOT_ID} .bp-smoke{
  background:
    radial-gradient(circle at 35% 35%, rgba(255,255,255,0.18), transparent 60%),
    rgba(255,255,255,0.05);
  filter: blur(1.1px);
}
#${ROOT_ID} .bp-spark{
  background:
    radial-gradient(circle at 40% 40%, rgba(255,220,140,0.55), transparent 60%),
    rgba(255,120,0,0.14);
  filter: blur(0.2px);
}
#${ROOT_ID} .bp-leg{
  transform-origin: 50% 0%;
  animation: bp-leg 0.18s linear infinite;
}
#${ROOT_ID} .bp-leg.alt{
  animation-delay: 0.09s;
}
@keyframes bp-leg{
  0%{transform: rotate(12deg)}
  50%{transform: rotate(-12deg)}
  100%{transform: rotate(12deg)}
}
    `.trim();

    const style = document.createElement("style");
    style.id = STYLE_ID;
    style.textContent = css;
    document.head.appendChild(style);
  }

  function createRoot(zIndex) {
    let root = document.getElementById(ROOT_ID);
    if (root) return root;

    root = document.createElement("div");
    root.id = ROOT_ID;
    root.style.zIndex = String(zIndex ?? DEFAULTS.zIndex);

    const layer = document.createElement("div");
    layer.className = "bp-layer";
    root.appendChild(layer);

    document.documentElement.appendChild(root);
    return root;
  }

  function bullSVG(theme = "sunset") {
    const palettes = {
      sunset: {
        body1: "#5a1f0e",   // deep copper
        body2: "#1b0a06",   // espresso
        body3: "#7a2c14",   // highlight
        horn1: "#fff1d6",
        horn2: "#d9c49a",
        accent: "#ff9f1c",
      },
      ember: {
        body1: "#3b1d0f",
        body2: "#120605",
        body3: "#512410",
        horn1: "#f8f1e1",
        horn2: "#d7c6a3",
        accent: "#ffb703",
      },
      midnight: {
        body1: "#0c1327",
        body2: "#05070f",
        body3: "#132045",
        horn1: "#f5f1e6",
        horn2: "#cfc3a8",
        accent: "#7dd3fc",
      },
    };

    const c = palettes[theme] || palettes.sunset;

    return `
<svg viewBox="0 0 220 140" width="100%" height="100%" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">
  <defs>
    <linearGradient id="bp-body" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="${c.body3}"/>
      <stop offset="45%" stop-color="${c.body1}"/>
      <stop offset="100%" stop-color="${c.body2}"/>
    </linearGradient>
    <linearGradient id="bp-horn" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="${c.horn1}"/>
      <stop offset="100%" stop-color="${c.horn2}"/>
    </linearGradient>
    <radialGradient id="bp-glow" cx="30%" cy="30%" r="75%">
      <stop offset="0%" stop-color="${c.accent}" stop-opacity="0.18"/>
      <stop offset="100%" stop-color="${c.accent}" stop-opacity="0"/>
    </radialGradient>
  </defs>

  <ellipse cx="120" cy="70" rx="110" ry="70" fill="url(#bp-glow)"/>

  <rect x="70" y="45" rx="28" ry="28" width="130" height="70"
        fill="url(#bp-body)" stroke="rgba(255,255,255,0.08)"/>

  <rect x="60" y="50" rx="24" ry="24" width="70" height="60"
        fill="url(#bp-body)" opacity="0.98"/>

  <g transform="translate(10,35)">
    <rect x="35" y="18" rx="18" ry="18" width="65" height="60"
          fill="url(#bp-body)" stroke="rgba(255,255,255,0.08)"/>
    <rect x="28" y="8" rx="999" ry="999" width="26" height="14"
          fill="url(#bp-horn)" transform="rotate(-12 41 15)"/>
    <rect x="81" y="8" rx="999" ry="999" width="26" height="14"
          fill="url(#bp-horn)" transform="rotate(12 94 15)"/>
    <circle cx="55" cy="40" r="4.6" fill="#0b0b0b"/>
    <circle cx="55" cy="40" r="8" fill="none"
            stroke="${c.accent}" stroke-opacity="0.22" stroke-width="2"/>
    <rect x="42" y="58" rx="10" ry="10" width="35" height="18"
          fill="#0a0302" opacity="0.9"/>
  </g>

  <rect x="196" y="74" rx="999" ry="999" width="22" height="8" fill="url(#bp-body)"/>
  <circle cx="220" cy="78" r="5" fill="#070707"/>

  <g>
    <rect class="bp-leg" x="95" y="98" rx="8" ry="8" width="18" height="38" fill="#070707"/>
    <rect class="bp-leg alt" x="122" y="98" rx="8" ry="8" width="18" height="38" fill="#070707"/>
    <rect class="bp-leg alt" x="155" y="98" rx="8" ry="8" width="18" height="38" fill="#050505"/>
    <rect class="bp-leg" x="178" y="98" rx="8" ry="8" width="18" height="38" fill="#050505"/>
  </g>
</svg>
    `.trim();
  }

  function clamp(n, min, max) {
    return Math.max(min, Math.min(max, n));
  }

  function bell(p) {
    return Math.sin(Math.PI * clamp(p, 0, 1));
  }

  function easeInOut(p) {
    p = clamp(p, 0, 1);
    return p < 0.5 ? 2 * p * p : 1 - Math.pow(-2 * p + 2, 2) / 2;
  }

  function spawnParticle(layer, cls, x, y, size, vx, vy, life) {
    const el = document.createElement("div");
    el.className = cls;
    el.style.width = `${size}px`;
    el.style.height = `${size}px`;
    el.style.left = `${x}px`;
    el.style.top = `${y}px`;
    layer.appendChild(el);

    const start = performance.now();
    const g = cls.includes("bp-smoke") ? 8 : 18;

    function tick(now) {
      const t = now - start;
      const p = clamp(t / life, 0, 1);

      const dx = vx * p;
      const dy = vy * p + g * p * p;

      const scale = cls.includes("bp-smoke") ? 1 + p * 1.2 : 1 + p * 0.35;

      el.style.transform = `translate(${dx}px, ${dy}px) scale(${scale})`;
      el.style.opacity = String(1 - p);

      if (p < 1) requestAnimationFrame(tick);
      else el.remove();
    }
    requestAnimationFrame(tick);
  }

  function burstDustAndSmoke(layer, x, y, strength, theme) {
    const s = clamp(strength, 0, 1);

    const dustCount = 1 + Math.round(2 * s);
    for (let i = 0; i < dustCount; i++) {
      const size = 6 + Math.random() * 10 * (0.7 + s);
      const angle = Math.PI + (Math.random() * 0.9 - 0.45);
      const v = 50 + Math.random() * 120 * (0.5 + s);
      const vx = Math.cos(angle) * v;
      const vy = Math.sin(angle) * v - 20 * s;

      spawnParticle(
        layer,
        "bp-dust",
        x + (Math.random() * 14 - 7),
        y + (Math.random() * 10 - 5),
        size,
        vx * 0.12,
        vy * 0.1,
        420 + Math.random() * 260
      );
    }

    if (s > 0.35) {
      const smokeCount = Math.round(1 + 2 * s);
      for (let i = 0; i < smokeCount; i++) {
        const size = 10 + Math.random() * 18 * s;
        const vx = -10 + Math.random() * 20;
        const vy = -25 - Math.random() * 35 * s;

        spawnParticle(
          layer,
          "bp-smoke",
          x + (Math.random() * 20 - 10),
          y - 8 + (Math.random() * 10 - 5),
          size,
          vx,
          vy,
          900 + Math.random() * 450
        );
      }
    }

    // Sparks for warm palettes
    if (theme !== "midnight" && s > 0.55) {
      const sparkCount = 1 + Math.round(2 * s);
      for (let i = 0; i < sparkCount; i++) {
        const size = 3 + Math.random() * 4;
        const vx = -20 + Math.random() * 40;
        const vy = -40 - Math.random() * 50 * s;
        spawnParticle(
          layer,
          "bp-spark",
          x + (Math.random() * 10 - 5),
          y - 10 + (Math.random() * 6 - 3),
          size,
          vx * 0.25,
          vy * 0.22,
          320 + Math.random() * 180
        );
      }
    }
  }

  function applyShake(envelope, opts) {
    if (prefersReduced) return;

    const amp = opts.shakeMax * envelope;
    const rotAmp = opts.rotateMax * envelope;

    const sx = (Math.random() - 0.5) * amp * 2;
    const sy = (Math.random() - 0.5) * amp * 2;
    const sr = (Math.random() - 0.5) * rotAmp * 2;

    document.body.style.transform =
      `translate(${sx.toFixed(2)}px, ${sy.toFixed(2)}px) rotate(${sr.toFixed(3)}deg)`;
  }

  function clearShake() {
    document.body.style.transform = "";
  }

  function run(userOpts = {}) {
    injectStyles();

    const opts = { ...DEFAULTS, ...userOpts };
    const root = createRoot(opts.zIndex);
    const layer = root.querySelector(".bp-layer");

    const bull = document.createElement("div");
    bull.className = "bp-bull";
    bull.innerHTML = bullSVG(opts.colorTheme);
    layer.appendChild(bull);

    const vw = window.innerWidth;
    const vh = window.innerHeight;

    const rect = bull.getBoundingClientRect();
    const bullW = rect.width || 180;
    const bullH = rect.height || 120;

    // Direction: the SVG faces LEFT by default.
    // To move RIGHT while facing RIGHT, we flip horizontally.
    const movingRight = opts.direction !== "left";

    const startX = movingRight ? -bullW - 40 : vw + bullW + 40;
    const endX   = movingRight ? vw + bullW + 40 : -bullW - 40;

    const groundY =
      vh - (opts.groundOffset + Math.round(bullH * 0.35));
    const baseY = groundY;

    let lastParticle = 0;
    const startTime = performance.now();

    return new Promise((resolve) => {
      function frame(now) {
        const elapsed = now - startTime;
        const p = clamp(elapsed / opts.duration, 0, 1);

        const moveP = easeInOut(p);
        const x = startX + (endX - startX) * moveP;

        const bob =
          Math.sin(elapsed * (prefersReduced ? 0.01 : 0.02)) *
          (prefersReduced ? 1.5 : 4.5);

        const env = bell(p);

        const tilt = (prefersReduced ? 0 : 1) * (env * 6) * Math.sin(elapsed * 0.02);
        const squash = 1 + env * 0.06;

        // Flip logic:
        // SVG faces left; if we are moving right, flip to face right.
        const flipX = movingRight ? -1 : 1;

        bull.style.left = `${x.toFixed(1)}px`;
        bull.style.top = `${(baseY + bob).toFixed(1)}px`;
        bull.style.transform =
          `scale(${(opts.bullScale * squash).toFixed(3)}) ` +
          `scaleX(${flipX}) rotate(${tilt.toFixed(2)}deg)`;

        applyShake(env, opts);

        const dynamicRate = clamp(
          opts.particleRate * (1.25 - env * 0.9),
          10,
          60
        );

        if (elapsed - lastParticle >= dynamicRate) {
          lastParticle = elapsed;

          const hoofX = x + bullW * 0.35;
          const hoofY = baseY + bullH * 0.72;

          const strength = prefersReduced ? 0.35 : env;
          burstDustAndSmoke(layer, hoofX, hoofY, strength, opts.colorTheme);
        }

        if (p < 1) {
          requestAnimationFrame(frame);
        } else {
          clearShake();
          bull.remove();
          setTimeout(() => {
            if (layer && layer.childElementCount === 0) root.remove();
            resolve();
          }, 300);
        }
      }

      requestAnimationFrame(frame);
    });
  }

  global.BullParty = { run };
})(window);
BullParty.run();