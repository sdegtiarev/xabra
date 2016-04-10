module local.spline;
import std.exception;
import std.conv;


Spline!T spline(T)(T[] x, T[] y)
{
	return Spline!T(x,y);
}

struct Spline(T)
{
	private immutable ulong N;
	private T[] X,A,B,C,D;

	@property T min() const { return X[0]; }
	@property T max() const { return X[N]; }

	T opCall(T x) const {
		enforce(x >= min && x <= max, "spline argument "~to!string(x)~" is out of range ["~to!string(min)~", "~to!string(max)~"]");
		size_t i;
		for(i=N-1; i > 0 && x < X[i]; --i) {}
		auto h=x-X[i];
		return A[i]+h*(B[i]+h*(C[i]+h*D[i]));
	}

	T der1(T x) const {
		enforce(x >= min && x <= max, "spline argument "~to!string(x)~" is out of range ["~to!string(min)~", "~to!string(max)~"]");
		size_t i;
		for(i=N-1; i > 0 && x < X[i]; --i) {}

		auto h=x-X[i];
		return B[i]+h*(2*C[i]+h*3*D[i]);
	}

	T der2(T x) const {
		enforce(x >= min && x <= max, "spline argument "~to!string(x)~" is out of range ["~to!string(min)~", "~to!string(max)~"]");
		size_t i;
		for(i=N-1; i > 0 && x < X[i]; --i) {}

		auto h=x-X[i];
		return 2*(C[i]+h*3*D[i]);
	}
	

	this(const(T)[] x, const(T)[] y)
	{
		assert(x.length == y.length);
		X=x.dup;
		A=y.dup;
		N=x.length-1;
		C.length=N+1;
		B.length=D.length=N;

		T[] p,u,d;
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

	immutable size_t N=5;
	float[] x,y;
	float dx=PI/N;
	foreach(i; 0..N+1) {
		auto t=i*dx;
		x~=t;
		y~=sin(t);
	}

	auto s=spline!float(x, y);
	immutable size_t M=100;
	dx=PI/M;
	writeln("sin(x)");
	foreach(i; 0..M+1) {
		auto tx=fabs(i*dx-1e-8);
		auto ty=s(tx);
		//writeln(tx, " ", ty-sin(tx));
		writeln(tx, " ", ty);
	}
	writeln("sin'(x)");
	foreach(i; 0..M+1) {
		auto tx=fabs(i*dx-1e-8);
		auto ty=s.der1(tx);
		//writeln(tx, " ", ty-cos(tx));
		writeln(tx, " ", ty);
	}
	writeln("sin''(x)");
	foreach(i; 0..M+1) {
		auto tx=fabs(i*dx-1e-8);
		auto ty=s.der2(tx);
		//writeln(tx, " ", ty-cos(tx));
		writeln(tx, " ", ty);
	}


}