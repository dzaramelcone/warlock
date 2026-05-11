import shader_abi;

[shader("vertex")]
Warlock::SurfaceVaryings main(Warlock::VertexInput input) {
    Warlock::SurfaceVaryings output;
    float4 clip = mul(transpose(Warlock::vertexPush.mvp), float4(input.position, 1.0));
    clip.y = -clip.y;
    output.position = clip;
    output.color = Warlock::unpackColor(input.color);
    output.uv = input.uv;
    output.barycentric = input.barycentric;
    output.edgeMask = input.edgeMask;
    return output;
}
