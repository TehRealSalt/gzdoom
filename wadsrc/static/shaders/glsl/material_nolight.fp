
vec3 ProcessMaterialLight(Material material, vec3 color)
{
	vec3 frag = SnapApplyLight(material.Base.rgb, color);
	return SnapApplyDynamicLight(frag, desaturate(uDynLightColor).rgb);
}
