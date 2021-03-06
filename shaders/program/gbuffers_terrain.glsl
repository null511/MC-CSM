#extension GL_ARB_gpu_shader5 : enable

#define RENDER_TERRAIN

varying vec2 lmcoord;
varying vec2 texcoord;
varying vec4 glcolor;
varying vec3 vPos;
varying vec3 vNormal;
varying float geoNoL;

#ifdef SHADOW_ENABLED
	#if SHADOW_TYPE == 3
		varying vec4 shadowPos[4];
		varying vec2 shadowProjectionSize[4];
		flat varying vec3 shadowTileColor;
	#elif SHADOW_TYPE != 0
		varying vec4 shadowPos;
	#endif
#endif

#ifdef RENDER_VERTEX
	in vec4 mc_Entity;
	in vec3 vaPosition;
	in vec3 at_midBlock;

	uniform mat4 gbufferModelView;
	uniform mat4 gbufferModelViewInverse;
	uniform float frameTimeCounter;
	uniform vec3 cameraPosition;

    #if MC_VERSION >= 11700
    	uniform vec3 chunkOffset;
    #endif

	#include "/lib/waving.glsl"

	#ifdef SHADOW_ENABLED
		uniform mat4 shadowModelView;
		uniform mat4 shadowProjection;
		uniform vec3 shadowLightPosition;
		uniform float far;

		#if SHADOW_TYPE == 3
            #ifdef IS_OPTIFINE
                uniform mat4 gbufferPreviousModelView;
            #endif

			uniform mat4 gbufferProjection;
			uniform float near;

			#include "/lib/shadows/csm.glsl"
			#include "/lib/shadows/csm_render.glsl"
		#elif SHADOW_TYPE != 0
			#include "/lib/shadows/basic.glsl"
		#endif
	#endif

	#include "/lib/lighting/basic.glsl"


	void main() {
		texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
		lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
		glcolor = gl_Color;

		BasicVertex();
	}
#endif

#ifdef RENDER_FRAG
	uniform sampler2D texture;
	uniform sampler2D lightmap;

	#ifdef SHADOW_ENABLED
		uniform sampler2D shadowcolor0;
		uniform sampler2D shadowtex0;
		uniform sampler2D shadowtex1;

        #ifdef SHADOW_ENABLE_HWCOMP
            uniform sampler2DShadow shadow;
        #endif
		
		uniform vec3 shadowLightPosition;

		#if SHADOW_PCF_SAMPLES == 12
			#include "/lib/shadows/poisson_12.glsl"
		#elif SHADOW_PCF_SAMPLES == 24
			#include "/lib/shadows/poisson_24.glsl"
		#elif SHADOW_PCF_SAMPLES == 36
			#include "/lib/shadows/poisson_36.glsl"
		#endif

		#if SHADOW_TYPE == 3
			#include "/lib/shadows/csm.glsl"
			#include "/lib/shadows/csm_render.glsl"
		#elif SHADOW_TYPE != 0
			uniform mat4 shadowProjection;

			#include "/lib/shadows/basic.glsl"
		#endif
	#endif

	#include "/lib/lighting/basic.glsl"


	void main() {
		vec4 color = BasicLighting();

		#if SHADOW_TYPE == 3 && defined DEBUG_CASCADE_TINT && defined SHADOW_ENABLED
			color.rgb *= 1.0 - LOD_TINT_FACTOR * (1.0 - shadowTileColor);
		#endif

		ApplyFog(color);

		color.rgb = LinearToRGB(color.rgb);

	/* DRAWBUFFERS:0 */
		gl_FragData[0] = color; //gcolor
	}
#endif
