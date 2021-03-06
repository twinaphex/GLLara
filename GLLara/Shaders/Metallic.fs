/*
 * Now this one's a weird shader. It uses bump maps and reflection, but does not add any specular highlights. I'll be damned if I know why. I use the normal maps for the diffuse component anyway.
 */

in vec4 outColor;
in vec2 outTexCoord;
in vec3 positionWorld;
in mat3 tangentToWorld;

out vec4 screenColor;

uniform sampler2D diffuseTexture;
uniform sampler2D bumpTexture;
uniform sampler2D reflectionTexture;

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
	float reflectionAmount;
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
		// Diffuse term; this version does not use specular
		color += diffuseTexColor * lightData.lights[i].diffuseColor * max(dot(-normal, lightData.lights[i].direction.xyz), 0);
	}
	
	// Apply reflection
	vec3 reflectionDir = normalize(reflect(cameraDirection, normal));
	
	// Reflection dir now points at a sphere. We ignore the z component to get a circle. But we still have to scale it to get to the square XNAlara demands.
	float tanAlpha = reflectionDir.x/reflectionDir.y;
	float cotAlpha = reflectionDir.y/reflectionDir.x;
	float scaleFactor = sqrt(min(1, tanAlpha*tanAlpha) + min(1, cotAlpha*cotAlpha));
	vec2 reflectionTexCoord = scaleFactor * reflectionDir.xy;
	vec4 reflectionColor = texture(reflectionTexture, reflectionTexCoord * 0.5 + 0.5);
	
#ifdef USE_ALPHA_TEST
    float alpha = diffuseTexColor.a;
#else
    float alpha = 1.0;
#endif
	screenColor = vec4(mix(color.rgb, reflectionColor.rgb, parameters.reflectionAmount), alpha);
}
