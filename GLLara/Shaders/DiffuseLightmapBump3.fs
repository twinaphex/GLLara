/*
 * Advanced multi-step version of DiffuseLightmapBump. This uses not one, not two, but three bump maps! There is one master bump map. It's result is then modified by the two detail bump maps, which are repeated quite often and essentially include the high-frequency detail information. They seem to be used mostly for cloth pattern and the like.
 *
 * After the more complicated way of getting the bump map normal, it is identical to DiffuseLightmapBump.
 */
#version 150

in vec4 outColor;
in vec2 outTexCoord;
in vec3 normalWorld;
in vec3 positionWorld;
in mat3 tangentToWorld;

out vec4 screenColor;

uniform sampler2D diffuseTexture;
uniform sampler2D lightmapTexture;
uniform sampler2D bumpTexture;
uniform sampler2D bump1Texture;
uniform sampler2D bump2Texture;
uniform sampler2D maskTexture;

uniform vec3 cameraPosition;

layout(std140) uniform Light {
	vec4 color;
	vec3 direction;
	float intensity;
	float shadowDepth;
} lights[3];

uniform float bumpSpecularGloss;
uniform float bumpSpecularAmount;
uniform float bump1UVScale;
uniform float bump2UVScale;

void main()
{
	vec4 diffuseColor = texture(diffuseColor, outTexCoord) * outColor;
	vec4 normalMap = texture(bumpTexture, outTexCoord);
	vec4 detailNormalMap1 = texture(bump1Texture, outTexCoord * bump1UVScale);
	vec4 detailNormalMap2 = texture(bump2Texture, outTexCoord * bump2UVScale);
	vec4 maskColor = texture(maskTexture, outTexCoord);
	
	vec4 lightmapColor = texture(lightmapTexture, outTexCoord);
	
	// Combine normal textures
	vec3 normalColor = normalMap.rgb + (detailNormalMap1.rgb - 0.5) * maskColor.r + (detailNormalMap2.rgb - 0.5) * maskColor.g;
	
	// Derive actual normal
	vec3 normalFromMap = vec3(normalMap.rg * 2 - 1, normalMap.b);
	vec3 normal = normalize(tangentToWorld * normalFromMap);
	
	vec3 cameraDirection = normalize(positionWorld - cameraPosition);
	
	vec4 color = vec4(0);
	for (int i = 0; i < 3; i++)
	{
		// Calculate diffuse factor
		float diffuseFactor = clamp(dot(normal, -lights[i].direction), 0, 1);
		float diffuseShading = mix(1, factor, lights[i].shadowDepth);
		
		// Calculate specular factor
		vec3 refLightDir = -reflect(lights[i].direction, normal);
		float specularFactor = clamp(dot(cameraDirection, refLightDir), 0, 1);
		float specularShading = diffuseFactor * pow(specularFactor, bumpSpecularGloss) * bumpSpecularAmount;
		
		// Make diffuse color brighter by specular amount, then apply normal diffuse shading (that means specular highlights are always white).
		// Include lightmap color, too.
		vec4 lightenedColor = diffuseColor + vec4(vec3(specularShading), 1.0);
		color += lights[i].color * diffuseShading * lightenedColor * lightmapColor;
	}
	
	color.a = diffuseColor.a;
	
	screenColor = color;
}