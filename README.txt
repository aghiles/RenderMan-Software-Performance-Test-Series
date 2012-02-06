(c) 2004 Maas Digital LLC
Modified by Aghiles Kheffache to reflect current status (2012)

REQUIREMENTS
------------

You must have a RenderMan-compliant renderer installed such that
the shaders and RIB files in this project can be coompiled and
rendered.

Default shader compiler is 'shaderdl' and the default renderer is
'renderdl', both are part of the 3Delight distribution. To use
PrMan please modify dobench.sh and change these command names to
'shader' and 'prman'.

INSTRUCTIONS
------------

Simply run the script dobench.sh.

   ./dobench.sh

dobench.sh works on Linux and Mac OSX only. On other platforms,
you must compile bench.sl and stucco.sl manually, then
time each of the RIB renderings - except geom.rib.

dobench.sl writes some system information and the benchmark times to
a file called output.txt in the current directory. Additionally, each
RIB will produce statistics from the renderer. Statistics files will
have the same name as the RIB but with the .txt extension.

Note that all output files are overwritten each time you run the
the benchmark, so rename it to something else if you want to keep
them.

The rendered images will be named the same as the test, e.g.
shader.tif, hider.tif, etc.

TEST INFO
---------

There are seven tests, each of which exercises a different part of the
a renderer. These tests should each take about 5-10 minutes to
render.

The "shader" test stresses the shader interpreter along with some
commonly used shadeops (noise and spline) by running a complex
shader on a very simple piece of geometry.

The "shader_vm" is like "shader" but doesn't run the noise() function
which is quite costly. It is meant as a more accurate timing of the
shader VM.

The "hider" test stresses the hider by rendering with depth of field,
motion blur, and a high number of samples.

The "diffuse raytracing" test simulates ambient occlusion raytracing.

The "diffuse raytracing+disp" test simulates ambient occlusion
raytracing on displaced geometry.

The "diffuse raytracing+shade" test simulates ambient occlusion
raytracing but runs the shader at each ray hit.

The "specular raytracing" test simulates reflection raytracing.

On the ray tracing tests, I've used a typical number of samples from
production shots, but set the shading rate somewhat high, in order to
make the renders finish in a reasonable amonut of time. In a
production setting the shading rate would be set to 1 or less.

Which tests you should pay attention to depends on your typical
production workload. If you aren't using much ray tracing, then the
"shader" and "hider" tests are probably about equal in importance.  If
you are using ambient occlusion, then look at the "diffuse raytracing"
test. If you use raytraced reflections, then look at the "specular
raytracing" test.

COPYRIGHT INFO
--------------

This package is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program (GPL.txt); if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307,
USA.
