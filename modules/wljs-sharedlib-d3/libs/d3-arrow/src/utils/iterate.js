export function iterate(attrs, path) {
  const keys = Object.keys(attrs), l = keys.length;
  for (let i = 0; i < l; i++){
    const key = keys[i];
    path.attr(key, attrs[key]);
  }
}