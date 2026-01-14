# Graphics3D engine based on THREE.js
*written with love in Javascript*

![](imgs/screenshot(17).png)

```mathematica
Graphics3D[{
    {Emissive[Red], Sphere[{0,0,2}]}, 
    {White, Sphere[]}
}, Lighting->None, RTX->True]
```

---

See disscussion at [mathematica.stackexchange](https://mathematica.stackexchange.com/a/215025/53728).

__This is a core component of [Wolfram JS Frontend](https://github.com/JerryI/wolfram-js-frontend) project__

## Examples
Most Mathematica's functions for 3D plotting expands into a bunch of `Graphics3D` primitives

```mathematica
ContourPlot3D[x^3 + y^2 - z^2 == 0, {x, -2, 2}, {y, -2, 2}, {z, -2, 2}]
```

![](imgs/screenshot(20).png)

However, styling and labeling is not implemented

```mathematica
VectorPlot3D[{x, y, z}, {x, -1, 1}, {y, -1, 1}, {z, -1, 1}, VectorColorFunction -> Function[{x, y, z, vx, vy, vz, n}, ColorData["ThermometerColors"][x]]][[1]];
%/. {RGBColor[r_,g_,b_] :> Sequence[RGBColor[r/50,g/50,b/50], Emissive[RGBColor[r,g,b], 5]],};

Graphics3D[{%, Roughness[0], Sphere[{0,0,0}, 0.9]}, Lighting->None, RTX->True]
```

![](imgs/screenshot(19).png)

Custom lighting, mesh materials, shadows propeties are provided

![](imgs/screenshot(5).png)

![](imgs/screenshot(8).png)

## Docs?
See [HERE](https://jerryi.github.io/wljs-docs/frontend/Reference/Graphics3D/)

## License

Project is released under the GNU General Public License (GPL).
