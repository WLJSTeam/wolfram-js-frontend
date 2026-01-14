const loader = async (self) => {
    self["d3"] = await import('./index-5a456ecd.js');
    self["d3-interpolate-path"] = await import('./d3-interpolate-path-3a6490dc.js');
    self["d3-arrow"] = await import('./index-2ecbb95a.js');
    console.log('D3 shared library loaded!');
  };

  new interpretate.shared(
    "d3",
    loader
  );
