HEADER
{
	Description = "Template Shader for S&box";
}

FEATURES
{
    Feature(F_USE_NORMAL_MAP, 0..1, "MToon Lighting");
    #include "common/features.hlsl"
    Feature(F_RENDERING_TYPE, 0..3(0="Opaque", 1="Cutout", 2="Transparent", 3="TransparentWithZWrite"), "Rendering");
    Feature(F_DEBUGGING_OPTIONS, 0..2(0="None", 1="Normal", 2="LitShadeRate"), "MToon Debug");
}

COMMON
{
	#include "common/shared.hlsl"
	#define F_DISABLE_Z_PREPASS 0
}

struct VertexInput
{
	#include "common/vertexinput.hlsl"
};

struct PixelInput
{
	#include "common/pixelinput.hlsl"
};

VS
{
	#include "common/vertex.hlsl"

	PixelInput MainVs( VertexInput i )
	{
		PixelInput o = ProcessVertex( i );
		return  FinalizeVertex( o );
	}
}

//=========================================================================================================================

PS
{
	#define CUSTOM_MATERIAL_INPUTS
    StaticCombo(S_RENDER_BACKFACES, F_RENDER_BACKFACES, Sys(ALL));

    StaticCombo(S_USE_NORMAL_MAP, F_USE_NORMAL_MAP, Sys(ALL));
    StaticCombo(S_RENDERING_TYPE, F_RENDERING_TYPE, Sys(ALL));
    StaticCombo(S_DEBUGGING_OPTIONS, F_DEBUGGING_OPTIONS, Sys(ALL));

    RenderState(DepthEnable, true);
    RenderState(DepthFunc, LESS_EQUAL);

    #if S_RENDERING_TYPE == 1 // Cutout
        #define ALPHA_TEST 1
        RenderState(AlphaTestEnable, true);
        RenderState(DepthWriteEnable, true);
    #elif S_RENDERING_TYPE == 2 // Transparent
        #define TRANSLUCENT 1
        BoolAttribute(translucent, true);
        RenderState(DepthWriteEnable, false);
    #elif S_RENDERING_TYPE == 3 // TransparentWithZWrite
        #define TRANSLUCENT 1
        BoolAttribute(translucent, true);
        RenderState(DepthWriteEnable, true);
    #else // Opaque
        RenderState(DepthWriteEnable, true);
    #endif
	
	#include "common/pixel.hlsl"

	CreateInputTexture2D(InputLitTexture, Srgb, 8, "", "", "MToon Color,1/Texture,1/1", Default4(1.0, 1.0, 1.0, 1.0));
    CreateTexture2D(LitTexture)< Channel(RGBA, Box(InputLitTexture), Srgb); OutputFormat(BC7); SrgbRead(true); >;
    float4 LitColor < UiType(Color); Default4(1.0, 1.0, 1.0, 1.0); UiGroup("MToon Color,1/Texture,1/2"); >;
	float LitIntensity < UiType(Slider);Range(0.0,10.0); Default(1.0); UiGroup("MToon Color,1/Texture,1/4"); >;
    CreateInputTexture2D(InputShadeTexture, Srgb, 8, "", "", "MToon Color,1/Texture,1/3", Default4(1.0, 1.0, 1.0, 1.0));
    CreateTexture2D(ShadeTexture)< Channel(RGBA, Box(InputShadeTexture), Srgb); OutputFormat(BC7); SrgbRead(true); >;
    float4 ShadeColor < UiType(Color); Default4(0.97, 0.81, 0.86, 1.0); UiGroup("MToon Color,1/Texture,1/4"); >;
	CreateInputTexture2D( Normal, Linear, 8, "NormalizeNormals", "_normal", "Material,10/20", Default3( 0.5, 0.5, 1.0 ) );
	Texture2D g_tNormal < Channel( RGBA, Box( Normal ), linear ); OutputFormat( BC7 ); SrgbRead( false ); >;
    #if ALPHA_TEST
        float Cutoff < UiType(Slider); Range(0.0, 1.0); Default1(0.5); UiGroup("MToon Color,1/Alpha,2/1"); >;
    #endif

    float ShadingToony < UiType(Slider); Range(0.0, 1.0); Default1(0.9); UiGroup("MToon Lighting,2/1"); >;

    float ShadingShift < UiType(Slider); Range(-1.0, 1.0); Default1(0.0); UiGroup("MToon Lighting,2/Advanced Settings,2/1"); >;
    CreateInputTexture2D(InputShadingGradeTexture, Srgb, 8, "", "", "MToon Lighting,2/Advanced Settings,2/2", Default4(0.5, 0.5, 0.5, 1.0));
    CreateTexture2D(ShadingGradeTexture)< Channel(RGBA, Box(InputShadingGradeTexture), Srgb); OutputFormat(BC7); SrgbRead(true); >;
    float ShadingGradeRate < UiType(Slider); Range(0.0, 1.0); Default1(0.1); UiGroup("MToon Lighting,2/Advanced Settings,2/3"); >;
    float LightColorAttenuation < UiType(Slider); Range(0.0, 1.0); Default1(0.0); UiGroup("MToon Lighting,2/Advanced Settings,2/4"); >;
    float IndirectLightIntensity < UiType(Slider); Range(0.0, 1.0); Default1(0.0); UiGroup("MToon Lighting,2/Advanced Settings,2/5"); >;

    CreateInputTexture2D(InputEmissionMap, Srgb, 8, "", "", "MToon Emission,3/1", Default4(1.0, 1.0, 1.0, 1.0));
    CreateTexture2D(EmissionMap)< Channel(RGBA, Box(InputEmissionMap), Srgb); OutputFormat(BC7); SrgbRead(true); >;
    float4 EmissionColor < UiType(Color); Default4(0.0, 0.0, 0.0, 1.0); UiGroup("MToon Emission,3/2"); >;
    CreateInputTexture2D(InputMatCap, Srgb, 8, "", "", "MToon Emission,3/3", Default4(0.0, 0.0, 0.0, 1.0));
    CreateTexture2D(MatCap)< Channel(RGBA, Box(InputMatCap), Srgb); OutputFormat(BC7); SrgbRead(true); >;
	float matcapStrength < UiType(Slider); Range(0.0,1.0); Default(0.0); UiGroup("MToon Emission,3/4"); >;
    CreateInputTexture2D(InputRimTexture, Srgb, 8, "", "", "MToon Rim,4/1", Default4(0, 0, 0, 1.0));
    CreateTexture2DWithoutSampler(RimTexture)< Channel(RGBA, Box(InputRimTexture), Srgb); OutputFormat(BC7); SrgbRead(true); >;
    float4 RimColor < UiType(Color); Default4(0.0, 0.0, 0.0, 1.0); UiGroup("MToon Rim,4/2"); >;
    float RimLightingMix < UiType(Slider); Range(0.0, 1.0); Default1(0.0); UiGroup("MToon Rim,4/3"); >;
    float RimFresnelPower < UiType(Slider); Range(0.0, 100.0); Default1(1.0); UiGroup("MToon Rim,4/4"); >;
    float RimLift < UiType(Slider); Range(0.0, 1.0); Default1(0.0); UiGroup("MToon Rim,4/5"); >;

	static const float PI_2 = 6.28318530718;
    static const float EPS_COL = 0.00001;

    static float2 mainUv;
    static float4 mainTex;
    static float alpha;

    static float3 positionWithOffsetWs;
    static float3 positionWs;
    static float3 viewRayWs;
    static float3 normalWs;

    static float4 lit;
    static float4 shade;
    static float shadingGrade;

    static float lightIntensity;
    static float3 lighting;
    static float3 indirectLighting;

    #if S_RENDER_BACKFACES
        static bool isFrontFace;
    #endif

	void Init(PixelInput i, Material m)
	{
		mainUv = i.vTextureCoords;
		mainTex = LitTexture.Sample(g_sAniso, mainUv);

		alpha = 1;
		#if ALPHA_TEST
			alpha = LitColor.a * mainTex.a;
			alpha = (alpha - Cutoff) / max(fwidth(alpha), EPS_COL) + 0.5; // Alpha to Coverage
			clip(alpha - Cutoff);
			alpha = 1.0; // Discarded, otherwise it should be assumed to have full opacity
		#endif
		#if TRANSLUCENT
			alpha = LitColor.a * mainTex.a;
			#if !ALPHA_TEST // Only enable this on D3D11, where I tested it
				clip(alpha - 0.0001); // Slightly improves rendering with layered transparency
			#endif
		#endif
		positionWithOffsetWs = i.vPositionWithOffsetWs;
        positionWs = positionWithOffsetWs + g_vCameraPositionWs;
		viewRayWs = CalculatePositionToCameraDirWs(positionWs);

		#if S_USE_NORMAL_MAP
            normalWs = m.Normal;
        #else
            normalWs = float3(i.vNormalWs.x, i.vNormalWs.y, i.vNormalWs.z);
        #endif

		normalWs *= step(0, dot(viewRayWs, normalWs)) * 2 - 1; // flip if projection matrix is flipped
        normalWs = normalize(normalWs);

		lit = LitColor * mainTex;
		//uncomment to use seperate shade texture
		//shade = ShadeColor * ShadeTexture.Sample(g_sAniso,mainUv);
		shade = ShadeColor * mainTex;
		shadingGrade = 1.0 - ShadingGradeRate * (1.0 - ShadingGradeTexture.Sample(g_sAniso,mainUv).r);
	}

	float4 Direct(PixelInput i, Material m, Light l)
	{
		float dotNL = dot(l.Direction, normalWs);

		lightIntensity = dotNL;
		lightIntensity = lightIntensity * 0.5 + 0.5;
		lightIntensity = lightIntensity * l.Visibility * l.Attenuation;
		lightIntensity *= shadingGrade;
		lightIntensity = lightIntensity * 2.0 - 1.0;

		float maxIntensityThreshold = lerp(1,ShadingShift,ShadingToony);
		float minIntensityThreshold = ShadingShift;

		lightIntensity = saturate((lightIntensity-minIntensityThreshold)/max(EPS_COL,(maxIntensityThreshold-minIntensityThreshold)));

		float3 resultColor = lerp(shade.rgb,lit.rgb*LitIntensity,lightIntensity);

		float3 lightColor = saturate(l.Visibility * l.Attenuation * l.Color);

		lighting = lightColor;
		lighting = lerp(lighting,max(EPS_COL,max(lighting.x,max(lighting.y,lighting.z))),LightColorAttenuation);

		resultColor *= lighting*l.Color;

		return float4(resultColor,1);
		
	}

	float4 Indirect(PixelInput i, Material m)
    {
		float3 resultColor = float3(0,0,0);

		Light light = AmbientLight::From(m.WorldPosition, m);

		float3 toonedGI = 0.5 * (light.Color + light.Color);
		indirectLighting = lerp(float3(0,0,0), toonedGI, IndirectLightIntensity);
		indirectLighting = lerp(indirectLighting, max(EPS_COL, max(indirectLighting.x, max(indirectLighting.y, indirectLighting.z))), LightColorAttenuation); // color atten
		resultColor = indirectLighting * lit.rgb;

		resultColor = min(resultColor, lit.rgb); // comment out if you want to PBR absolutely.

		return float4(resultColor,0);
    }

	float4 PostProcess(float4 color)
	{
		float3 staticRimLighting = 1;
		float3 mixedRimLighting = lighting + indirectLighting;
		float3 rimLighting = lerp(staticRimLighting,mixedRimLighting,RimLightingMix);
		float3 rim = pow(saturate(1.0 - dot(normalWs,viewRayWs)+RimLift),max(RimFresnelPower,EPS_COL))*RimColor.rgb;
		color.rgb += rim * rimLighting;

		float3 worldCameraUp = normalize(g_vCameraUpDirWs);
		float3 worldViewUp = normalize(worldCameraUp - viewRayWs * dot(viewRayWs,worldCameraUp));
		float3 worldViewRight = normalize(cross(viewRayWs,worldViewUp));
		float2 matcapUv = float2(dot(worldViewRight,normalWs),dot(worldViewUp,normalWs)) * 0.5 + 0.5;
		float3 matcapLighting = MatCap.Sample(g_sAniso,matcapUv).rgb;
		color.rgb += matcapLighting*matcapStrength;

		float3 emission = EmissionMap.Sample(g_sAniso,mainUv).rgb * EmissionColor.rgb;
		color.rgb += emission;

            // debug
            #if S_DEBUGGING_OPTIONS == 1
                return float4(normalWs * 0.5 + 0.5, alpha);
            #elif S_DEBUGGING_OPTIONS == 2
                return float4(lightIntensity * lighting, alpha);
            #endif

            return float4(color.rgb, alpha);
	}

	float4 MainPs( PixelInput i ) : SV_Target0
	{
		Material m = Material::From(i, float4(0,0,0,0),float4(i.vNormalWs,0),float4(1,1,1,0));
		m.Normal = TransformNormal( DecodeNormal(g_tNormal.Sample(g_sAniso,i.vTextureCoords).rgb) , i.vNormalWs, i.vTangentVWs, i.vTangentUWs ).rgb;
		Init(i,m);
		m.Normal = normalWs;
		float3 vColor = float3(0,0,0);

		float3 vLightResult = float3(0,0,0);

		for (int index = 0; index < DynamicLight::Count(m.ScreenPosition); index++)
        {
            Light light = DynamicLight::From(m.ScreenPosition, m.WorldPosition, index);
            vLightResult += Direct(i, m, light).rgb;
        }

		vLightResult += Indirect(i, m).rgb;

		vColor = PostProcess(float4(vLightResult,1)).rgb;

		vColor = DoAtmospherics(m.WorldPosition,m.ScreenPosition.xy,float4(vColor,0)).xyz;
		return float4(vColor,0);
	}
}
