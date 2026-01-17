function s(o, r, e = void 0) {
    let n = () => {
    };
    return (...t) => (n(), new Promise((c, i) => {
      const u = setTimeout(() => c(o(...t)), r);
      n = () => {
        clearTimeout(u), e !== void 0 && i(e);
      };
    }));
  }
  export {
    s as debouncePromise
  };