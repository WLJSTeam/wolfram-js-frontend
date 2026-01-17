export const RevealPointer = (function () {
  "use strict";

  const KEYCODES = {q: 81};

  // Utility to clamp values
  const clamp = (v, min, max) => Math.max(min, Math.min(max, v));

  return function () {
    // ------ state ------
    let cfg = {};
    let enabled = false;
    let container = null;

    // Main dot and tail elements
    let dot = null;
    let tailEls = []; // array of HTMLDivElement
    let trail = [];   // [{x,y}] newest first

    // pointer position within the container's own (unscaled) coordinates
    const pos = { x: 0, y: 0, isVisible: false };

    // ------ config ------
    function loadConfig(api) {
      const p = (api.getConfig && api.getConfig().pointer) || {};
      cfg.key = (p.key ?? "q").toLowerCase();
      cfg.pointerSize = (typeof p.pointerSize === "number" ? p.pointerSize : 12);
      cfg.tailLength = clamp((typeof p.tailLength === "number" ? p.tailLength : 10), 0, 60);
      cfg.color = (typeof p.color === "string" ? p.color : "red");
      cfg.alwaysVisible = (typeof p.alwaysVisible === "boolean" ? p.alwaysVisible : false);
      cfg.opacity = (typeof p.opacity === "number" ? p.opacity : 0.8);
      cfg.keyCode = KEYCODES[cfg.key];
    }

    // ------ dom helpers ------
    function createDot() {
      if (dot) return;

      const d = document.createElement("div");
      d.className = "cursor-dot";
      Object.assign(d.style, {
        position: "absolute",
        top: "0",
        left: "0",
        transform: "translate(0, 0)",
        width: `${cfg.pointerSize}px`,
        height: `${cfg.pointerSize}px`,
        backgroundColor: cfg.color,
        borderRadius: "50%",
        pointerEvents: "none",
        opacity: "0",
        transition: "opacity 120ms linear",
        willChange: "transform",
      });

      container.appendChild(d);
      dot = d;
    }

    function createTail() {
      destroyTail(); // reset
      if (cfg.tailLength <= 0) return;

      for (let i = 0; i < cfg.tailLength; i++) {
        const seg = document.createElement("div");
        const sizeFactor = 1 - (i + 1) / (cfg.tailLength + 1); // smaller further away
        const segSize = Math.max(2, Math.round(cfg.pointerSize * (0.4 + 0.6 * sizeFactor)));

        Object.assign(seg.style, {
          position: "absolute",
          top: "0",
          left: "0",
          transform: "translate(0, 0)",
          width: `${segSize}px`,
          height: `${segSize}px`,
          backgroundColor: cfg.color,
          borderRadius: "50%",
          pointerEvents: "none",
          opacity: "0",
          transition: "opacity 120ms linear",
          willChange: "transform, opacity",
          // Subtle blur can look nice; comment out if undesired:
          // filter: "blur(0.2px)",
        });

        container.appendChild(seg);
        tailEls.push(seg);
      }
    }

    function destroyDot() {
      if (!dot) return;
      dot.remove();
      dot = null;
    }

    function destroyTail() {
      tailEls.forEach(el => el.remove());
      tailEls = [];
      trail = [];
    }

    // ------ rendering ------
    function render() {
      // Main dot
      if (dot) {
        dot.style.transform = `translate(${pos.x}px, ${pos.y}px)`;
        dot.style.opacity = pos.isVisible ? String(cfg.opacity) : "0";
        dot.style.width = `${cfg.pointerSize}px`;
        dot.style.height = `${cfg.pointerSize}px`;
        dot.style.backgroundColor = cfg.color;
      }

      // Tail
      if (tailEls.length) {
        for (let i = 0; i < tailEls.length; i++) {
          const seg = tailEls[i];
          const p = trail[i];
          if (!p || !pos.isVisible) {
            seg.style.opacity = "0";
            continue;
          }

          // Fade and size gradient along the tail
          const t = (i + 1) / (tailEls.length + 1);
          const alpha = cfg.opacity * (1 - t); // farther -> more transparent
          const baseSize = Math.max(2, Math.round(cfg.pointerSize * (1 - 0.6 * t)));
          seg.style.width = `${baseSize}px`;
          seg.style.height = `${baseSize}px`;

          // Center each segment on its tracked point
          const sx = p.x - baseSize / 2;
          const sy = p.y - baseSize / 2;

          seg.style.transform = `translate(${sx}px, ${sy}px)`;
          seg.style.opacity = String(alpha);
          seg.style.backgroundColor = cfg.color;
        }
      }
    }

    // ------ events ------
    function onMove(ev) {
      if (!container) return;

      const rect = container.getBoundingClientRect();
      const ow = container.offsetWidth || 1;
      const oh = container.offsetHeight || 1;
      const scaleX = rect.width / ow;
      const scaleY = rect.height / oh;
      const scale = scaleX || 1; // Reveal is uniform scale

      // Convert viewport coords -> container coords -> unscale to layout pixels
      const x = (ev.clientX - rect.left) / scale;
      const y = (ev.clientY - rect.top) / scale;

      // Center the dot on the pointer
      pos.x = x - cfg.pointerSize / 2;
      pos.y = y - cfg.pointerSize / 2;

      // Record trail head as the uncentered point (real pointer position in container coords)
      // Using uncentered keeps tail centered on the true cursor.
      const head = { x, y };
      trail.unshift(head);
      if (trail.length > cfg.tailLength) trail.length = cfg.tailLength;

      requestAnimationFrame(render);
    }

    function toggle() {
      enabled = !enabled;
      if (enabled) {
        createDot();
        createTail();
        container.addEventListener("mousemove", onMove);
        container.classList.add("no-cursor"); // scoped to container (not body)
        pos.isVisible = true;
        requestAnimationFrame(render);
      } else {
        container.removeEventListener("mousemove", onMove);
        container.classList.remove("no-cursor");
        pos.isVisible = false;
        requestAnimationFrame(render);
        // Clean up DOM when disabled
        destroyTail();
        destroyDot();
      }
    }

    // ------ public plugin API for Reveal ------
    return {
      id: "pointer",
      init(api) {
        loadConfig(api);
        container = api.getRevealElement();

        // Ensure container can position absolutely positioned children
        const cs = getComputedStyle(container);
        if (cs.position === "static") {
          container.style.position = "relative";
        }

        // Color updates (work even if dot/tail not yet created)
        api.on("pointerColorChange", ({ color }) => {
          cfg.color = color ?? cfg.color;
          if (dot) dot.style.backgroundColor = cfg.color;
          tailEls.forEach(el => (el.style.backgroundColor = cfg.color));
        });

        if (cfg.alwaysVisible) {
          enabled = true;
          createDot();
          createTail();
          pos.isVisible = true;
          container.addEventListener("mousemove", onMove);
          container.classList.add("no-cursor");
          requestAnimationFrame(render);
        } else {
          api.addKeyBinding({ keyCode: cfg.keyCode, key: cfg.key }, () => toggle());
        }
      },
    };
  };
})();
