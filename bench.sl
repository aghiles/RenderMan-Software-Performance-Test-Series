/* see readme.txt for copyright info */

/* attempt to stress the shader interpreter
   this is a modified version of the Mandelbrot fractal
   algorithm, with noise() called for each iteration
   as an option. */
color shader_bench(float u; float v; float call_noise )
{
	float i;
	float x = 0, y = 0;

	float MAXIT = 256; /* max # of iterations */

	for(i = 0; i < MAXIT; i += 1) {
		float oldx = x, oldy = y;
		
		/* Z = Z^2 + C */
		x = oldx*oldx - oldy*oldy + u;
		y = 2*oldx*oldy + v;

		/* throw in some noise just for fun */
		if( call_noise == 1 )
		{
			point noiz = point noise(point(10*x, 10*y, 0));
			x += 0.07*xcomp(noiz);
			y += 0.07*ycomp(noiz);
		}

		/* check for escape */
		float rsquared = x*x + y*y;
		if(rsquared > 10) {
			break;
		}
	}

	/* output of Mandelbrot iteration */
	float c = i/MAXIT;
	return color spline(pow(1-c, 2),
			    color(0),
			    color(0),
			    color(1, 0, 0),
			    color(0, 0, 1),
			    color(1),
			    color(1));
}

surface bench(
	string mode = "simple";
	float samples = 16; /* only used in raytrace modes */
	float ray_bias = 0.001;
	float call_noise = 1;
	float modulate_opacity = 0;)
{
	normal NN = normalize(N);
	
	Oi = Os;
	
	if(mode == "raydiff") {
		/* diffuse raytracing (ambient occlusion) test */
		float occ = occlusion(P, NN,
				      samples,
				      "adaptive", 1,
				      "maxerror", 0,
				      "bias", ray_bias,
				      "maxdist", 5000);
		Ci = Oi * (1-occ);
		
	} else if(mode == "rayspec") {
		/* specular raytracing (raytraced reflections) test */

		/* get ray depth */
		float depth;
		rayinfo("depth", depth);

		if(depth > 1) {
			/* don't recurse more than once */
			Ci = color(0);
		} else {
			float maxsamples, minsamples, coneangle;
			if(depth == 0) {
				/* initial ray bundle, use normal # of samples */
				maxsamples = samples;
				minsamples = samples/4;
				coneangle = radians(2.5);
			} else {
				/* secondary ray shots, use only 1 sample */
				maxsamples = 1;
				minsamples = 1;
				coneangle = 0;
			}
			
			vector II = normalize(I);

			/* shoot the rays */
			color hitcolor = 0, total = 0;
			gather("illuminance", P, reflect(II, NN), coneangle, maxsamples,
			       "distribution", "uniform", "bias", ray_bias,
			       "surface:Ci", hitcolor) {
				/* hit */
				total += hitcolor;
			} else {
				/* miss */
				total += color(1);
			}
			total /= maxsamples;
			
			Ci = Oi * total;
		}
		
	} else if(mode == "shader") {
		/* shader interpreter stress test */
		point oP = transform("object", P);
		Ci = Oi * shader_bench(xcomp(oP), ycomp(oP), call_noise);
		
	} else if(mode == "simple") {
		/* quick shader for hider test */
		Ci = Oi * (diffuse(NN) + ambient());
	}

	if( modulate_opacity != 0 )
		Oi *= noise(u,v)*0.1;
}
