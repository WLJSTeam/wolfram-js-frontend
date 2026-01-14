
  const loader = async (self) => {
    self["d3"] = await import('d3');
    self["d3-interpolate-path"] = await import('d3-interpolate-path');
    self["d3-arrow"] = await import("./../libs/d3-arrow/index.js");
    console.log('D3 shared library loaded!');
  }

  new interpretate.shared(
    "d3",
    loader
  );
