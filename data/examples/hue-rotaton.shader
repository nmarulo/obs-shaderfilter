// Hue Rotation shader, version 1.0 for OBS Shaderfilter
// Copyright ©️ 2023 by SkeletonBow
// License: GNU General Public License, version 2
//
// Contact info:
//		Twitter: <https://twitter.com/skeletonbowtv>
//		Twitch: <https://twitch.tv/skeletonbowtv>
//		YouTube: <https://youtube.com/@skeletonbow>
//		Soundcloud: <https://soundcloud.com/skeletonbowtv>
//
// Description:
//		Rotates hue of input at a user configurable speed. Negative speed values reverse rotation. A hue
//		override option is provided to force a specific rotating hue instead of the original image's hue.
//
// Changelog:
// 1.0	- Initial release

/*
   This program is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public License
   version 2 as published by the Free Software Foundation.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.
 
   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

uniform float Speed<
    string label = "Speed";
    string widget_type = "slider";
    float minimum = 0.0;
    float maximum = 100.0;
    float step = 0.001;
> = 10.00;
uniform bool Hue_Override = false;

float3 HUEtoRGB(in float H)
{
	float R = abs(H * 6 - 3) - 1;
	float G = 2 - abs(H * 6 - 2);
	float B = 2 - abs(H * 6 - 4);
	return saturate(float3(R,G,B));
}

#define Epsilon 1e-10
 
float3 RGBtoHCV(in float3 RGB)
{
	// Based on work by Sam Hocevar and Emil Persson
	float4 P = (RGB.g < RGB.b) ? float4(RGB.bg, -1.0, 2.0/3.0) : float4(RGB.gb, 0.0, -1.0/3.0);
	float4 Q = (RGB.r < P.x) ? float4(P.xyw, RGB.r) : float4(RGB.r, P.yzx);
	float C = Q.x - min(Q.w, Q.y);
	float H = abs((Q.w - Q.y) / (6 * C + Epsilon) + Q.z);
	return float3(H, C, Q.x);
}

float3 HSVtoRGB(in float3 HSV)
{
	float3 RGB = HUEtoRGB(HSV.x);
	return ((RGB - 1) * HSV.y + 1) * HSV.z;
}

float3 RGBtoHSV(in float3 RGB)
{
	float3 HCV = RGBtoHCV(RGB);
	float S = HCV.y / (HCV.z + Epsilon);
	return float3(HCV.x, S, HCV.z);
}

float4 mainImage( VertData v_in ) : TARGET
{
	float2 uv = v_in.uv;
	float4 col_in = image.Sample(textureSampler, uv);
	float3 col_out;
	float3 HSV = RGBtoHSV(col_in.rgb);

	if(Hue_Override)
		HSV.x = elapsed_time * Speed * 0.01;
	else
		HSV.x += elapsed_time * Speed * 0.01;

	// Normalize Hue	
	HSV.x = frac(HSV.x);
	
	col_out = HSVtoRGB(HSV);
	return float4(col_out, col_in.a);
}
