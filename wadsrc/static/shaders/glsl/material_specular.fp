
vec2 lightAttenuation(int i, vec3 normal, vec3 viewdir, float lightcolorA, float glossiness, float specularLevel)
{
	vec4 lightpos = lights[i];
	vec4 lightspot1 = lights[i+2];
	vec4 lightspot2 = lights[i+3];

	float lightdistance = distance(lightpos.xyz, pixelpos.xyz);
	if (lightpos.w < lightdistance)
		return vec2(0.0); // Early out lights touching surface but not this fragment

	float attenuation = clamp((lightpos.w - lightdistance) / lightpos.w, 0.0, 1.0);

	if (lightspot1.w == 1.0)
		attenuation *= spotLightAttenuation(lightpos, lightspot1.xyz, lightspot2.x, lightspot2.y);

	vec3 lightdir = normalize(lightpos.xyz - pixelpos.xyz);

	if (lightcolorA < 0.0) // Sign bit is the attenuated light flag
		attenuation *= clamp(dot(normal, lightdir), 0.0, 1.0);

	if (attenuation > 0.0) // Skip shadow map test if possible
		attenuation *= shadowAttenuation(lightpos, lightcolorA);

	attenuation *= SnapCelLightAttenuation(attenuation);
	if (attenuation <= 0.0)
		return vec2(0.0);

	vec3 halfdir = normalize(viewdir + lightdir);
	float specAngle = clamp(dot(halfdir, normal), 0.0f, 1.0f);
	float phExp = glossiness * 4.0f;
	return vec2(attenuation, attenuation * specularLevel * pow(specAngle, phExp));
}

vec3 ProcessMaterialLight(Material material, vec3 color)
{
	vec4 dynlight = uDynLightColor;
	vec4 specular = vec4(0.0, 0.0, 0.0, 1.0);

	vec3 normal = material.Normal;
	vec3 viewdir = normalize(uCameraPos.xyz - pixelpos.xyz);

	if (uLightIndex >= 0)
	{
		ivec4 lightRange = ivec4(lights[uLightIndex]) + ivec4(uLightIndex + 1);
		if (lightRange.z > lightRange.x)
		{
			// modulated lights
			for(int i=lightRange.x; i<lightRange.y; i+=4)
			{
				vec4 lightcolor = lights[i+1];
				vec2 attenuation = lightAttenuation(i, normal, viewdir, lightcolor.a, material.Glossiness, material.SpecularLevel);
				dynlight.rgb += lightcolor.rgb * attenuation.x;
				specular.rgb += lightcolor.rgb * attenuation.y;
			}

			// subtractive lights
			for(int i=lightRange.y; i<lightRange.z; i+=4)
			{
				vec4 lightcolor = lights[i+1];
				vec2 attenuation = lightAttenuation(i, normal, viewdir, lightcolor.a, material.Glossiness, material.SpecularLevel);
				dynlight.rgb -= lightcolor.rgb * attenuation.x;
				specular.rgb -= lightcolor.rgb * attenuation.y;
			}
		}
	}

	vec3 frag = SnapApplyLight(material.Base.rgb, color.rgb);
	frag = SnapApplyDynamicLight(frag, desaturate(dynlight).rgb);

	specular.rgb = clamp(desaturate(specular).rgb, 0.0, 1.4);
	frag += material.Specular * specular.rgb;

	if (uLightIndex >= 0)
	{
		ivec4 lightRange = ivec4(lights[uLightIndex]) + ivec4(uLightIndex + 1);
		if (lightRange.w > lightRange.z)
		{
			vec4 addlight = vec4(0.0,0.0,0.0,0.0);

			// additive lights
			for(int i=lightRange.z; i<lightRange.w; i+=4)
			{
				vec4 lightcolor = lights[i+1];
				vec2 attenuation = lightAttenuation(i, normal, viewdir, lightcolor.a, material.Glossiness, material.SpecularLevel);
				addlight.rgb += lightcolor.rgb * attenuation.x;
			}

			frag = SnapApplyDynamicLight(frag, desaturate(addlight).rgb);
		}
	}

	return frag;
}
