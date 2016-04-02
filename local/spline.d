module local.spline;
import std.exception;


Spline spline(double[] x, double[] y)
{
	return Spline(x,y);
}

struct Spline
{
	private immutable ulong N;
	private double[] X,A,B,C,D;

	@property double min() const { return X[0]; }
	@property double max() const { return X[N]; }

	double opCall(double x) {
		enforce(x >= min && x <= max, "spline argument out of range");
		size_t i;
		for(i=N-1; i > 0 && x < X[i]; --i) {}

		auto h=x-X[i];
		return A[i]+h*(B[i]+h*(C[i]+h*D[i]));
	}

	double der1(double x) {
		enforce(x >= min && x <= max, "spline argument out of range");
		size_t i;
		for(i=N-1; i > 0 && x < X[i]; --i) {}

		auto h=x-X[i];
		return B[i]+h*(2*C[i]+h*3*D[i]);
	}
	

	this(const(double)[] x, const(double)[] y)
	{
		assert(x.length == y.length);
		X=x.dup;
		A=y.dup;
		N=x.length-1;
		C.length=N+1;
		B.length=D.length=N;

		double[] p,u,d;
		p.length=u.length=d.length=N;
		foreach(i; 1..N) {
			auto h0=X[i]-X[i-1], h1=X[i+1]-X[i], h2=h0+h1;
			p[i]=3*((A[i+1]-A[i])/h1+(A[i-1]-A[i])/h0)/h2;
			C[i]=2;
			d[i]=h0/h2;
			u[i]=h1/h2;
		}
		C[0]=C[N]=p[0]=0;
		
		foreach(i; 2..N) {
			auto k=d[i-1]/C[i-1];
			C[i]-=u[i-1]*k;
			p[i]-=p[i-1]*k;
		}
		
		foreach_reverse(i; 1..N-1) {
			auto k=u[i+1]/C[i+1];
			C[i]-=k;
			p[i]-=p[i+1]*k;
		}
		foreach(i; 1..N) C[i]=p[i]/C[i];

		foreach(i; 0..N) {
			auto h=X[i+1]-X[i];
			D[i]=(C[i+1]-C[i])/h/3;
			B[i]=(A[i+1]-A[i])/h-h*(C[i]+h*D[i]);
		}
	}
}

unittest
{
	import std.math;
	import std.stdio;

	immutable size_t N=10;
	double[] x,y;
	double dx=2*PI/N;
	foreach(i; 0..N+1) {
		auto t=i*dx;
		x~=t;
		y~=sin(t);
	}

	auto s=spline(x, y);
	immutable size_t M=100;
	dx=2*PI/M;
	writeln("spline");
	foreach(i; 0..M+1) {
		auto tx=fabs(i*dx-1e-8);
		auto ty=s(tx);
		writeln(tx, " ", ty-sin(tx));
	}


}