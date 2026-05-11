import shader_abi;

[shader("fragment")]
float4 main(Warlock::SurfaceVaryings input) : SV_Target {
    float3 material = Warlock::unpackColor(Warlock::pixelPush.baseColor);
    float3 textureColor = Warlock::baseTexture.Sample(input.uv).rgb;
    float3 face = max(input.color * material * textureColor, float3(0.08));
    float3 edgeWidth = fwidth(input.barycentric);
    float3 edge = smoothstep(float3(0.0), edgeWidth * 1.2, input.barycentric);
    float3 maskedEdge = (1.0 - edge) * input.edgeMask;
    float wireStrength = asfloat(Warlock::pixelPush.wireStrengthBits);
    float wireFactor = max(max(maskedEdge.x, maskedEdge.y), maskedEdge.z) * wireStrength;
    float3 wire = float3(0.01, 0.012, 0.015);
    float3 color = lerp(face, wire, wireFactor);
    return float4(color, 1.0);
}
