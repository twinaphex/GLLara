/*
 * Bump-mapped rendering. This does not support the special weird bump map shadows that XNALara does; I may add them later, once I figured out what they do. (I could add them now, but I do not add code where I don't understand what it does, thank you very much). A fun detail: Apparently only things with bumpmaps get specular highlights, and apparently the diffuse light value is not modified by the bumpmap. Not sure why; it doesn't cost anything extra.
 */

in vec4 outColor;
in vec2 outTexCoord;
in vec3 positionWorld;
in mat3 tangentToWorld;

out vec4 screenColor;

uniform sampler2D diffuseTexture;
uniform sampler2D bumpTexture;

struct Light {
	vec4 diffuseColor;
	vec4 specularColor;
	vec4 direction;
};

layout(std140) uniform LightData {
	vec4 cameraPosition;
	vec4 ambientColor;
	Light lights[3];
} lightData;

uniform RenderParameters {
	float bumpSpecularGloss;
	float bumpSpecularAmount;
} parameters;

#ifdef USE_ALPHA_TEST
layout(std140) uniform AlphaTest {
    uint mode; // 0 - none, 1 - pass if greater than, 2 - pass if less than.
    float reference;
} alphaTest;
#endif

void main()
{
	// Find diffuse texture and do alpha test.
    vec4 diffuseTexColor = texture(diffuseTexture, outTexCoord);
    
#ifdef USE_ALPHA_TEST
    if ((alphaTest.mode == 1U && diffuseTexColor.a <= alphaTest.reference) || (alphaTest.mode == 2U && diffuseTexColor.a >= alphaTest.reference))
        discard;
#endif
	
	// Base diffuse color
	vec4 diffuseColor = diffuseTexColor * outColor;

	// Calculate normal
	vec4 normalMap = texture(bumpTexture, outTexCoord);
	vec3 normalFromMap = normalMap.rgb * 2 - 1;
	vec3 normal = normalize(tangentToWorld * normalFromMap);
	
	// Direction to camera
	vec3 cameraDirection = normalize(lightData.cameraPosition.xyz - positionWorld);
	
	vec4 color = lightData.ambientColor * diffuseColor;
	for (int i = 0; i < 3; i++)
	{
		// Diffuse term
		float diffuseFactor = max(dot(-normal, lightData.lights[i].direction.xyz), 0);
		color += diffuseTexColor * lightData.lights[i].diffuseColor * diffuseFactor;
		
		// Specular term
		vec3 reflectedLightDirection = reflect(lightData.lights[i].direction.xyz, normal);
		float specularFactor = pow(max(dot(cameraDirection, reflectedLightDirection), 0), parameters.bumpSpecularGloss) * parameters.bumpSpecularAmount;
		if (diffuseFactor <= 0.001) specularFactor = 0;
		color += lightData.lights[i].specularColor * specularFactor;
	}
	
#ifdef USE_ALPHA_TEST
    float alpha = diffuseTexColor.a;
#else
    float alpha = 1.0;
#endif
	screenColor = vec4(color.rgb, alpha);
}
