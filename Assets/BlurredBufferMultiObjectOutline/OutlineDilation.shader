Shader "Hidden/Dilation"
{
    Properties
    {
        _Spread("Spread", Integer) = 0
    }

    SubShader
    {
        Tags
        {
            "RenderType"="Opaque" "RenderPipeline" = "UniversalPipeline"
        }
        LOD 100
        ZWrite Off Cull Off

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"

        SAMPLER(sampler_BlitTexture);

        float _Spread;
        ENDHLSL

        Pass
        {
            Name "HorizontalDilation"
            ZTest Always

            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment frag_vertical

            float4 frag_vertical(Varyings i) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
            
                // dilate with blending
                float3 blendedColor = float3(0, 0, 0);
                float totalWeight = 0;
            
                for (int x = -_Spread; x <= _Spread; x++)
                {
                    float2 uv = i.texcoord + float2(_BlitTexture_TexelSize.x * x, 0.0f);
                    float4 buffer = SAMPLE_TEXTURE2D_X(_BlitTexture, sampler_BlitTexture, uv);
            
                    // smoother blending
                    int distance = abs(x);
                    float falloff = exp(-pow(distance / _Spread, 2)); // gaussian falloff
                    float weight = buffer.a * falloff;
            
                    blendedColor += buffer.xyz * weight;
                    totalWeight += weight;
                }
            
                // normalize the color by the total weight
                blendedColor /= max(totalWeight, 0.0001f); // no division by zero
                float alpha = saturate(totalWeight / _Spread);
            
                return step(0.5,float4(blendedColor, alpha));
            }

            ENDHLSL
        }

        Pass
        {
            Name "VerticalDilation"
            ZTest Always
            Blend SrcAlpha OneMinusSrcAlpha

            Stencil
            {
                Ref 15
                Comp NotEqual
                Pass Zero
                Fail Zero
                ZFail Zero
            }

            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment frag_horizontal

            float4 frag_horizontal(Varyings i) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
            
                // dilate with blending
                float3 blendedColor = float3(0, 0, 0);
                float totalWeight = 0;
            
                for (int y = -_Spread; y <= _Spread; y++)
                {
                    float2 uv = i.texcoord + float2(0.0f, _BlitTexture_TexelSize.y * y);
                    float4 buffer = SAMPLE_TEXTURE2D_X(_BlitTexture, sampler_BlitTexture, uv);
            
                    // smoother blending
                    int distance = abs(y);
                    float falloff = exp(-pow(distance / _Spread, 2)); // gaussian falloff
                    float weight = buffer.a * falloff;
            
                    blendedColor += buffer.xyz * weight;
                    totalWeight += weight;
                }
            
                // normalize the color by the total weight
                blendedColor /= max(totalWeight, 0.0001f); // no division by zero
                float alpha = saturate(totalWeight / _Spread);
            
                return step(0.5,float4(blendedColor, alpha));
            }
            ENDHLSL
        }
    }
}