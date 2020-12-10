Shader "Custom/GrassShader"
{
    Properties
    {
        _AlbedoTex ("Albedo (RGB)", 2D) = "white" {}
        _AlphaTex ("Alpha", 2D) = "white" {}
        _BladeWidth ("Grass Blade Width", range(0, 0.1)) = 0.05
        _BladeHeight ("Grass Blade Height", float) = 2.5
        _OscillateDelta ("Oscillate Delta", float) = 0.05
    }
    SubShader
    {
        Cull off
        Tags{ "Queue" = "AlphaTest" "RenderType" = "TransparentCutout" "IgnoreProjector" = "True" }

        Pass
        {
			Cull OFF
			Tags{ "LightMode" = "ForwardBase" }
			AlphaToMask On

            CGPROGRAM
            #pragma require geometry
            
            #include "UnityCG.cginc" 
            #pragma vertex Vertex
            #pragma geometry Geometry
            #pragma fragment Fragment

            #pragma target 4.0

            sampler2D _AlbedoTex;
            sampler2D _AlphaTex;
            float _BladeWidth;
            float _BladeHeight;
            float _OscillateDelta;

            struct v2g
            {
                float4 pos : SV_POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct g2f
            {
                float4 pos : SV_POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            v2g Vertex(appdata_full input)
            {
                v2g output;
                output.pos = input.vertex;
                output.normal = input.normal;
                output.uv = input.texcoord;

                return output;
            }

            g2f MakeDefaultG2f()
            {
                g2f result;
                result.pos = float4(0, 0, 0, 0);
                result.normal = float3(0, 0, 0);
                result.uv = float2(0, 0);

                return result;
            }

            float CalcRandom(float2 pos)
            {
                return frac(sin(dot(pos.xy, float2(12.9898, 78.233))) * 43758.5453);
            }

            [maxvertexcount(30)]
            void Geometry(point v2g points[1], inout TriangleStream<g2f> triStream)
            {
                float4 base = points[0].pos;
                float displacement = CalcRandom(base.xz) * 0.5; // Scale down because our grass height is generally pretty low (<1)
                float bladeHalfWidth = _BladeWidth / 2;
                float bladeHeight = _BladeHeight + displacement;

                // Number of quads that make up the blade
                const int kQuadCount = 5;
                // Number of vertices necessary if we are using indices (i.e. vertex sharing between quads)
                const int kVertexCount = 2 * (kQuadCount + 1);
                // Vertical advance for UV coordinate
                const float kVerticalAdvance = 1.0f / kQuadCount;

                g2f v[kVertexCount];
                float uvHeight = 0;
                for (int i = 0; i < kVertexCount; i += 2) {
                    float2 wind = float2(sin(_Time.x * UNITY_PI * 5), sin(_Time.x * UNITY_PI * 5));
				    wind.x += (sin(_Time.x + base.x / 25) + sin((_Time.x + base.x / 15) + 50)) * 0.5;
				    wind.y += cos(_Time.x + base.z / 80);
				    wind *= lerp(0.7, 1.0, 1.0 - displacement);

                    float windCoEff = uvHeight;
				    float oscillationStrength = 2.5;
				    float sinSkewCoeff = displacement;
				    float lerpCoeff = (sin(oscillationStrength * _Time.x + sinSkewCoeff) + 1.0) / 2;
				    float2 leftWindBound = wind * (1.0 - _OscillateDelta);
				    float2 rightWindBound = wind * (1.0 + _OscillateDelta);

				    wind = lerp(leftWindBound, rightWindBound, lerpCoeff);

				    float randomAngle = lerp(-UNITY_PI, UNITY_PI, displacement);
				    float randomMagnitude = lerp(0, 1., displacement);
				    float2 randomWindDir = float2(sin(randomAngle), cos(randomAngle));
				    wind += randomWindDir * randomMagnitude;

				    float windForce = length(wind);

                    // Even vertices
                    v[i] = MakeDefaultG2f();
                    v[i].pos = float4(base.x - bladeHalfWidth, base.y + uvHeight * bladeHeight, base.z, 1.0);
                    v[i].pos.xz += wind.xy * windCoEff;
				    //v[i].pos.y -= windForce * windCoEff * 0.8;
                    v[i].pos = UnityObjectToClipPos(v[i].pos);
                    v[i].uv = float2(0.0, uvHeight);

                    // Odd vertices
                    v[i + 1] = MakeDefaultG2f();
                    v[i + 1].pos = float4(base.x + bladeHalfWidth, base.y + uvHeight * bladeHeight, base.z, 1.0);
                    v[i + 1].pos.xz += wind.xy * windCoEff;
				    //v[i + 1].pos.y -= windForce * windCoEff * 0.8;
                    v[i + 1].pos = UnityObjectToClipPos(v[i + 1].pos);
                    v[i + 1].uv = float2(1.0, uvHeight);

                    uvHeight += kVerticalAdvance;
                }

                for (int p = 0; p < kVertexCount - 2; ++p) {
                    triStream.Append(v[p]);
                    triStream.Append(v[p + 2]);
                    triStream.Append(v[p + 1]);
                }
            }

            float4 Fragment(g2f input) : COLOR
            {
                fixed4 color = tex2D(_AlbedoTex, input.uv);
                fixed4 alpha = tex2D(_AlphaTex, input.uv);

                // Alpha tex is black and white, any of r/g/b would work
                return float4(color.rgb, alpha.r);
            }
            ENDCG
        }
    }
}
