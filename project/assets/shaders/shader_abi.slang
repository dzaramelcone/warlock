namespace Warlock {
    namespace Slots {
        static const uint materialSet = 0;
        static const uint baseTexture = 0;
    }

    struct VertexInput {
        [[vk::location(0)]] float3 position : POSITION;
        [[vk::location(1)]] float2 uv : TEXCOORD0;
        [[vk::location(2)]] uint color : COLOR0;
        [[vk::location(3)]] float3 barycentric : TEXCOORD1;
        [[vk::location(4)]] float3 edgeMask : TEXCOORD2;
    };

    struct SurfaceVaryings {
        float4 position : SV_Position;
        [[vk::location(0)]] float3 color : COLOR0;
        [[vk::location(1)]] float2 uv : TEXCOORD0;
        [[vk::location(2)]] float3 barycentric : TEXCOORD1;
        [[vk::location(3)]] float3 edgeMask : TEXCOORD2;
    };

    struct VertexPush {
        float4x4 mvp;
        uint baseColor;
        uint shaderId;
    };

    struct PixelPush {
        float4x4 mvp;
        uint baseColor;
        uint shaderId;
        uint wireStrengthBits;
        uint pad1;
    };

    [vk::push_constant]
    uniform VertexPush vertexPush;

    [vk::push_constant]
    uniform PixelPush pixelPush;

    [[vk::binding(Slots::baseTexture, Slots::materialSet)]]
    Sampler2D baseTexture;

    float3 unpackColor(uint color) {
        float r = float((color >> 16) & 0xffu) / 255.0;
        float g = float((color >> 8) & 0xffu) / 255.0;
        float b = float(color & 0xffu) / 255.0;
        return float3(r, g, b);
    }
}
