module view;
import std.datetime;
import local.spline;
import std.stdio;

struct View
{
	DateTime at;
	Spline!double v;

	this(DateTime at, Spline!double sp) { this.at=at; this.v=sp; }

	@property double start() const { return v.min; }
	@property double end()   const { return v.max; }
	double opCall(double t)   const { return v.der1(t); }
	double value(double t)   const { return v(t); }
}



View normalize(View v)
{
	auto scale=v.v(v.end);
	return View(v.at, v.v*scale);
}


View smooth(View v, double dx)
{
	double[] x,y;
	x~=v.start;
	y~=v.v(v.start);
	for(double t=v.start+dx/2; t <= (v.end-dx/2); t+=dx) {
		x~=t;
		y~=(v.value(t-dx/2)+v.value(t)+v.value(t+dx/2))/3;
	}
	x~=v.end;
	y~=v.v(v.end);
	return View(v.at,spline(x,y));
}

View slice(View v, double x1, double x2)
{
	return View(v.at, v.v.slice(x1,x2));
}

View slice(View src, View target)
{
	return View(
		  target.at
		, src.v.slice(target.start, target.end)
			.shift(hr(target.at, src.at))
		);
}

double hr(DateTime start, DateTime end)
{
	return (end-start).total!"minutes"/60.;
}
