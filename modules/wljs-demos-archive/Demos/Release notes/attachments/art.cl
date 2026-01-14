
float3 palette( float t ) {
    float3 a = (float3)(0.5, 0.5, 0.5);
    float3 b = (float3)(0.5, 0.5, 0.5);
    float3 c = (float3)(1.0, 1.0, 1.0);
    float3 d = (float3)(0.263,0.416,0.557);

    return a + b*cos( 6.28318*(c*t+d) );
}

inline float2 fract(float2 x) {
  return x - floor(x);
}

//originally written by
//https://www.shadertoy.com/view/mtyGWy

__kernel void render(
  __global uchar4* output, 
  const int width, 
  const int height,
  float time
) {
    unsigned int work_item_id = get_global_id(0);
    
    unsigned int x_coord = work_item_id % width;
    unsigned int y_coord = work_item_id / width;

    float2 uv = (float2)(2.0f*(float)x_coord / (float)width - 1.0f, 2.0f*(float)y_coord / (float)height - 1.0f);  
    float2 uv0 = uv;
    
    float3 finalcolor = (float3)(0.0f, 0.0f, 0.0f);

    for (float i = 0.0; i < 4.0; i++) {
        uv = fract(uv * 1.5) - 0.5;

        float d = length(uv) * exp(-length(uv0));

        float3 col = palette(length(uv0) + i*.4 + time*.4);

        d = sin(d*8. + time)/8.;
        d = fabs(d);

        d = pow(0.01 / d, 1.2);

        finalcolor += col * d;
    }

    //clamp to 8bits for each channel
    
    uchar4 rgba;
    rgba.x=(uchar)(finalcolor.x*255.0);
    rgba.y=(uchar)(finalcolor.y*255.0);
    rgba.z=(uchar)(finalcolor.z*255.0);
    rgba.w=255;

    output[work_item_id] = rgba;
}