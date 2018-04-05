﻿// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Toony Colors Pro+Mobile 2
// (c) 2014-2017 Jean Moreno

Shader "Toony Colors Pro 2/Examples/Water/Realistic"
{
	Properties
	{
		[TCP2HelpBox(Warning,Make sure that the Camera renders the depth texture for this material to work properly.    You can use the script __TCP2_CameraDepth__ for this.)]
	[TCP2HeaderHelp(BASE, Base Properties)]
		//TOONY COLORS
		_HColor ("Highlight Color", Color) = (0.6,0.6,0.6,1.0)
		_SColor ("Shadow Color", Color) = (0.3,0.3,0.3,1.0)
		
		//DIFFUSE
		_MainTex ("Main Texture (RGB)", 2D) = "white" {}
	[TCP2Separator]
		
		//TOONY COLORS RAMP
		_RampThreshold ("Ramp Threshold", Range(0,1)) = 0.5
		_RampSmooth ("Ramp Smoothing", Range(0.001,1)) = 0.1
	[TCP2Separator]
	[TCP2HeaderHelp(WATER)]
		_Color ("Water Color (RGB) Opacity (A)", Color) = (0.5,0.5,0.5,1.0)
		
		[Header(Foam)]
		_FoamSpread ("Foam Spread", Range(0.01,5)) = 2
		_FoamStrength ("Foam Strength", Range(0.01,1)) = 0.8
		_FoamColor ("Foam Color (RGB) Opacity (A)", Color) = (0.9,0.9,0.9,1.0)
		[NoScaleOffset]
		_FoamTex ("Foam (RGB)", 2D) = "white" {}
		_FoamSmooth ("Foam Smoothness", Range(0,0.5)) = 0.02
		_FoamSpeed ("Foam Speed", Vector) = (2,2,2,2)
		[Header(Depth based Transparency)]
		[PowerSlider(5.0)] _DepthAlpha ("Depth Alpha", Range(0.01,10)) = 0.5
		_DepthMinAlpha ("Depth Min Alpha", Range(0,1)) = 0.5
		
		[Header(Waves Normal Map)]
		[TCP2HelpBox(Info,There are two normal maps blended. The tiling offsets affect each map uniformly.)]
		_BumpMap ("Normal Map", 2D) = "bump" {}
		[PowerSlider(2.0)] _BumpScale ("Normal Scale", Range(0.01,2)) = 1.0
		_BumpSpeed ("Normal Speed", Vector) = (0.2,0.2,0.3,0.3)
		
		[Header(Vertex Waves Animation)]
		_WaveSpeed ("Speed", Float) = 2
		_WaveHeight ("Height", Float) = 0.1
		_WaveFrequency ("Frequency", Range(0,10)) = 1
	[TCP2Separator]
	[TCP2HeaderHelp(SPECULAR, Specular)]
		//SPECULAR
		_SpecColor ("Specular Color", Color) = (0.5, 0.5, 0.5, 1)
		_Shininess ("Roughness", Range(0.0,10)) = 0.1
	[TCP2Separator]
	[TCP2HeaderHelp(REFLECTION, Reflection)]
		//REFLECTION
		_ReflRoughness ("Reflection Roughness", Range(0,1)) = 0
		_ReflStrength ("Reflection Strength", Range(0,1)) = 1
		_ReflStrength ("Reflection Strength", Range(0,1)) = 1
	[TCP2Separator]
	[TCP2HeaderHelp(RIM, Rim)]
		//RIM LIGHT
		_RimColor ("Rim Color", Color) = (0.8,0.8,0.8,0.6)
		_RimMin ("Rim Min", Range(0,1)) = 0.5
		_RimMax ("Rim Max", Range(0,1)) = 1.0
	[TCP2Separator]
	[TCP2HeaderHelp(TRANSPARENCY)]
		//Blending
		[Enum(UnityEngine.Rendering.BlendMode)] _SrcBlendTCP2 ("Blending Source", Float) = 5
		[Enum(UnityEngine.Rendering.BlendMode)] _DstBlendTCP2 ("Blending Dest", Float) = 10
	[TCP2Separator]

		//Avoid compile error if the properties are ending with a drawer
		[HideInInspector] __dummy__ ("unused", Float) = 0
	}
	
	SubShader
	{
		Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent"}
		Blend [_SrcBlendTCP2] [_DstBlendTCP2]
		
		
		CGPROGRAM
		
		#pragma surface surf ToonyColorsWater keepalpha vertex:vert nolightmap
		#pragma target 3.0
		
		//================================================================
		// VARIABLES
		
		fixed4 _Color;
		sampler2D _MainTex;
		float4 _MainTex_ST;
		sampler2D _BumpMap;
		float4 _BumpMap_ST;
		half _BumpScale;
		half4 _BumpSpeed;
		sampler2D_float _CameraDepthTexture;
		half4 _FoamSpeed;
		half _FoamSpread;
		half _FoamStrength;
		sampler2D _FoamTex;
		fixed4 _FoamColor;
		half _FoamSmooth;
		half _DepthAlpha;
		fixed _DepthMinAlpha;
		half unityTime;
		half _WaveHeight;
		half _WaveFrequency;
		half _WaveSpeed;
		
		fixed4 _RimColor;
		fixed _RimMin;
		fixed _RimMax;
		
		half _ReflStrength;
		half _ReflRoughness;

		struct Input
		{
			half2 texcoord;
			half2 bump_texcoord;
			half3 viewDir;
			float3 wPos;
			INTERNAL_DATA
			float4 sPos;
		};
		
		//================================================================
		// CUSTOM LIGHTING
		
		//Lighting-related variables
		half4 _HColor;
		half4 _SColor;
		float _RampThreshold;
		float _RampSmooth;
		fixed _Shininess;
		
		//Custom SurfaceOutput
		struct SurfaceOutputWater
		{
			fixed3 Albedo;
			fixed3 Normal;
			fixed3 Emission;
			half Specular;
			fixed Gloss;
			fixed Alpha;
		};
		
		inline half4 LightingToonyColorsWater (inout SurfaceOutputWater s, half3 lightDir, half3 viewDir, half atten)
		{
			s.Normal = normalize(s.Normal);
			fixed ndl = max(0, dot(s.Normal, lightDir));
			fixed3 ramp = smoothstep(_RampThreshold-_RampSmooth*0.5, _RampThreshold+_RampSmooth*0.5, ndl);
		#if !(POINT) && !(SPOT)
			ramp *= atten;
		#endif
			_SColor = lerp(_HColor, _SColor, _SColor.a);	//Shadows intensity through alpha
			ramp = lerp(_SColor.rgb, _HColor.rgb, ramp);
			fixed4 c;
			c.rgb = s.Albedo * _LightColor0.rgb * ramp;
			c.a = s.Alpha;
		#if (POINT || SPOT)
			c.rgb *= atten;
		#endif
			//Specular
			half3 h = normalize(lightDir + viewDir);
			float ndh = max(0, dot (s.Normal, h));
			float spec = pow(ndh, s.Specular*128.0) * s.Gloss * 2.0;
			spec *= atten;
			c.rgb += _LightColor0.rgb * _SpecColor.rgb * spec;
			return c;
		}

		//================================================================
		// VERTEX FUNCTION
		
		
		struct appdata_tcp2
		{
			float4 vertex : POSITION;
			float3 normal : NORMAL;
			float4 texcoord : TEXCOORD0;
			float4 texcoord1 : TEXCOORD1;
			float4 texcoord2 : TEXCOORD2;
			float4 tangent : TANGENT;
		};
		
			#define TIME unityTime
		
		void vert(inout appdata_tcp2 v, out Input o)
		{
			UNITY_INITIALIZE_OUTPUT(Input, o);
			
			//Main texture UVs
			float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
			o.wPos = worldPos;
			half2 mainTexcoords = worldPos.xz * 0.1;
			o.texcoord.xy = TRANSFORM_TEX(mainTexcoords.xy, _MainTex);
			o.bump_texcoord = mainTexcoords.xy + TIME.xx * _BumpSpeed.xy * 0.1;
			//vertex waves
			float3 _pos = worldPos.xyz * _WaveFrequency;
			float _phase = TIME * _WaveSpeed;
			half4 vsw_offsets = half4(1.0, 2.2, 0.6, 1.3);
			half4 vsw_ph_offsets = half4(1.0, 1.3, 2.2, 0.4);
			half4 waveXZ = sin((_pos.xxzz * vsw_offsets) + (_phase.xxxx * vsw_ph_offsets));
			// float waveFactorX = (waveXZ.x + waveXZ.y) * _WaveHeight / 2;
			// float waveFactorZ = (waveXZ.z + waveXZ.w) * _WaveHeight / 2;
			float waveFactorX = dot(waveXZ.xy, 1) * _WaveHeight / 2;
			float waveFactorZ = dot(waveXZ.zw, 1) * _WaveHeight / 2;
		#define VSW_STRENGTH 1
			v.vertex.y += (waveFactorX + waveFactorZ) * VSW_STRENGTH;
			half4 waveXZn = cos((_pos.xxzz * vsw_offsets) + (_phase.xxxx * vsw_ph_offsets)) * (vsw_offsets / 2);
			float xn = -_WaveHeight * (waveXZn.x + waveXZn.y);
			float zn = -_WaveHeight * (waveXZn.z + waveXZn.w);
			v.normal = normalize(float3(xn, 1, zn));
			float4 pos = UnityObjectToClipPos(v.vertex);
			o.sPos = ComputeScreenPos(pos);
			COMPUTE_EYEDEPTH(o.sPos.z);
		}

		//================================================================
		// SURFACE FUNCTION

		void surf(Input IN, inout SurfaceOutputWater o)
		{
			half3 normal = UnpackScaleNormal(tex2D(_BumpMap, IN.bump_texcoord.xy * _BumpMap_ST.xx), _BumpScale).rgb;
			half3 normal2 = UnpackScaleNormal(tex2D(_BumpMap, IN.bump_texcoord.xy * _BumpMap_ST.yy + TIME.xx * _BumpSpeed.zw  * 0.1), _BumpScale).rgb;
			normal = (normal+normal2)/2;
			o.Normal = normal;
			half ndv = dot(IN.viewDir, normal);
			fixed4 mainTex = tex2D(_MainTex, IN.texcoord.xy);
			float sceneZ = SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(IN.sPos));
			if(unity_OrthoParams.w > 0)
			{
				//orthographic camera
			#if defined(UNITY_REVERSED_Z)
				sceneZ = 1.0f - sceneZ;
			#endif
				sceneZ = (sceneZ * _ProjectionParams.z) + _ProjectionParams.y;
			}
			else
				//perspective camera
				sceneZ = LinearEyeDepth(sceneZ);
			float partZ = IN.sPos.z;
			float depthDiff = (sceneZ - partZ);
			//Depth-based foam
			half2 foamUV = IN.texcoord.xy;
			foamUV.xy += TIME.xx*_FoamSpeed.xy*0.05;
			fixed4 foam = tex2D(_FoamTex, foamUV);
			foamUV.xy += TIME.xx*_FoamSpeed.zw*0.05;
			fixed4 foam2 = tex2D(_FoamTex, foamUV);
			foam = (foam + foam2) / 2;
			float foamDepth = saturate(_FoamSpread * depthDiff);
			half foamTerm = (smoothstep(foam.r - _FoamSmooth, foam.r + _FoamSmooth, saturate(_FoamStrength - foamDepth)) * saturate(1 - foamDepth)) * _FoamColor.a;
			o.Albedo = lerp(mainTex.rgb * _Color.rgb, _FoamColor.rgb, foamTerm);
			_Color.a *= saturate((_DepthAlpha * depthDiff) + _DepthMinAlpha);
			o.Alpha = mainTex.a * _Color.a;
			o.Alpha = lerp(o.Alpha, _FoamColor.a, foamTerm);
			//Specular
			o.Gloss = 1;
			o.Specular = _Shininess;
			//Rim
			half3 rim = smoothstep(_RimMax, _RimMin, 1-Pow4(1-ndv)) * _RimColor.rgb * _RimColor.a;
			o.Emission += rim.rgb;
			half3 eyeVec = IN.wPos.xyz - _WorldSpaceCameraPos.xyz;
			half3 worldNormal = reflect(eyeVec, WorldNormalVector(IN, o.Normal));
			fixed3 reflColor = fixed3(0,0,0);
		#if UNITY_SPECCUBE_BOX_PROJECTION
			half3 worldNormal0 = BoxProjectedCubemapDirection (worldNormal, IN.wPos, unity_SpecCube0_ProbePosition, unity_SpecCube0_BoxMin, unity_SpecCube0_BoxMax);
		#else
			half3 worldNormal0 = worldNormal;
		#endif
			half3 env0 = Unity_GlossyEnvironment (UNITY_PASS_TEXCUBE(unity_SpecCube0), unity_SpecCube0_HDR, worldNormal0, _ReflRoughness);
			
		#if UNITY_SPECCUBE_BLENDING
			const float kBlendFactor = 0.99999;
			float blendLerp = unity_SpecCube0_BoxMin.w;
			UNITY_BRANCH
			if (blendLerp < kBlendFactor)
			{
			#if UNITY_SPECCUBE_BOX_PROJECTION
				half3 worldNormal1 = BoxProjectedCubemapDirection (worldNormal, IN.wPos, unity_SpecCube1_ProbePosition, unity_SpecCube1_BoxMin, unity_SpecCube1_BoxMax);
			#else
				half3 worldNormal1 = worldNormal;
			#endif
				
				half3 env1 = Unity_GlossyEnvironment (UNITY_PASS_TEXCUBE_SAMPLER(unity_SpecCube1,unity_SpecCube0), unity_SpecCube1_HDR, worldNormal1, _ReflRoughness);
				reflColor = lerp(env1, env0, blendLerp);
			}
			else
			{
				reflColor = env0;
			}
		#else
			reflColor = env0;
		#endif
			reflColor *= 0.5;
			o.Emission += reflColor.rgb * _ReflStrength;
		}
		
		ENDCG

	}
	
	//Fallback "Diffuse"
	CustomEditor "TCP2_MaterialInspector_SG"
}