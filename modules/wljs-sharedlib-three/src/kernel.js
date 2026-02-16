
  const loader = async (self) => {
    self.THREE         = (await import('three'));
    self.OrbitControls = (await import("three/examples/jsm/controls/OrbitControls.js")).OrbitControls;
    self.RGBELoader    = (await import('three/examples/jsm/loaders/RGBELoader.js')).RGBELoader; 
    self.CSS2D         = (await import('./../libs/labels.js'));
    
    console.log('THREE shared library loader!');
  }

  const loader1 = async (self) => {
    self.Water = (await import('three/examples/jsm/objects/Water.js')).Water
  }

  const loader2 = async (self) => {
    self.TransformControls =  (await import('three/addons/controls/TransformControls.js')).TransformControls
  }

  const loader3 = async (self) => {
    self.PointerLockControls = (await import('three/addons/controls/PointerLockControls.js')).PointerLockControls
  }

  const loader4 = async (self) => {
    self.RTX = (await import('three-gpu-pathtracer/build/index.module.js'));
  }

  const loader5 = async (self) => {
    const engine = await import("three/examples/jsm/renderers/CSS2DRenderer.js");
    self.CSS2DRenderer = engine.CSS2DRenderer;
    self.CSS2DObject = engine.CSS2DObject;
    //import { CSS2DRenderer, CSS2DObject } from 'three/examples/jsm/renderers/CSS2DRenderer.js'
  }

  const loader6 = async (self) => {
    const sprite = (await import("three-spritetext")).default;
    self.SpriteText = sprite;
  }

  

  new interpretate.shared(
    "THREE",
    loader
  );

  new interpretate.shared(
    "THREEWater",
    loader1
  );  

  new interpretate.shared(
    "THREETransformControls",
    loader2
  ); 

  new interpretate.shared(
    "THREEPointerLockControls",
    loader3
  )

  new interpretate.shared(
    "THREERTX",
    loader4
  )

  new interpretate.shared(
    "THREECSS",
    loader5
  )  

  new interpretate.shared(
    "SpriteText",
    loader6
  )
