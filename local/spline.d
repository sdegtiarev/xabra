module local.spline;
import std.exception;
import std.typecons;
import std.conv;
import std.stdio;


Spline!T spline(T)(const(T[]) x, const(T[]) y)
{
	return Spline!T(x,y);
}
Delta!T delta(T)(T x, T dx)
{
	return Delta!T(x,dx);
}



struct Delta(T)
{
	private T x, dx;

	@property bool empty() const { return false; }
	T front() const { return x; }
	void popFront() { x+=dx; }
}


Spline!T spline(T)(const ref Spline!T rh)
{
	return Spline!T(rh);
}

struct Spline(T)
{
	private ulong N;
	private T[] X,A,B,C,D;

	@property T min() const { return X[0]; }
	@property T max() const { return X[N]; }

	T opCall(T x) const {
		enforce((x+1e-6) >= min && (x-1e-6) <= max, "spline argument "~to!string(x)~" is out of range ["~to!string(min)~", "~to!string(max)~"]");
		size_t i;
		for(i=N-1; i > 0 && x < X[i]; --i) {}
		auto h=x-X[i];
		return A[i]+h*(B[i]+h*(C[i]+h*D[i]));
	}

	Spline opBinary(string op)(double scale) const
	{
		auto r=Spline(this);
		static if(op == "*") {
			r*=scale;
		} else static if(op == "/") {
			r/=scale;
		}
		return r;
	}

	void opOpAssign(string op)(T sc)
	{
		static if(op == "*") {
			foreach(i; 0..N+1) { A[i]*=sc; B[i]*=sc; C[i]*=sc; D[i]*=sc; }
		} else static if(op == "/") {
			foreach(i; 0..N+1) { A[i]/=sc; B[i]/=sc; C[i]/=sc; D[i]/=sc; }
		}
	}

	T D1(T x) const {
		enforce((x+1e-6) >= min && (x-1e-6) <= max, "spline argument "~to!string(x)~" is out of range ["~to!string(min)~", "~to!string(max)~"]");
		size_t i;
		for(i=N-1; i > 0 && x < X[i]; --i) {}

		auto h=x-X[i];
		return B[i]+h*(2*C[i]+h*3*D[i]);
	}
	Spline D1() const {
		return spline(X,B);
	}

	T D2(T x) const {
		enforce((x+1e-6) >= min && (x-1e-6) <= max, "spline argument "~to!string(x)~" is out of range ["~to!string(min)~", "~to!string(max)~"]");
		size_t i;
		for(i=N-1; i > 0 && x < X[i]; --i) {}

		auto h=x-X[i];
		return 2*(C[i]+h*3*D[i]);
	}
	Spline D2() const {
		return spline(X,C);
	}
	
	Spline S() const {
		T[] F;
		T value=0;
		F~=value;
		foreach(i; 0..N) {
			T h=X[i+1]-X[i];
			value+=h*(A[i]+h*(B[i]/2+h*(C[i]/3+h*D[i]/4)));
			F~=value;
		}
		return spline(X,F);
	}
	T S(T x) const {
		enforce((x+1e-6) >= min && (x-1e-6) <= max, "spline argument "~to!string(x)~" is out of range ["~to!string(min)~", "~to!string(max)~"]");
		T s=0;
		size_t i;
		for(i=0; i < N && x > X[i+1]; ++i) {
			auto h=X[i+1]-X[i];
			s+=h*(A[i]+h*(B[i]/2+h*(C[i]/3+h*D[i]/4)));
		}
		if(i < N) {
			auto h=x-X[i];
			s+=h*(A[i]+h*(B[i]/2+h*(C[i]/3+h*D[i]/4)));
		}
		return s;
	}


	this(const(T)[] x, const(T)[] y)
	{
		assert(x.length == y.length);
		X=x.dup;
		A=y.dup;
		N=x.length-1;
		C.length=B.length=D.length=N+1;

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
		auto h=X[N]-X[N-1];
		B[N]=B[N-1]+h*(2*C[N-1]+3*h*D[N-1]);
		D[N]=0;//???
	}

	this(const ref Spline!T rh) {
		this.N=rh.N;
		this.X=rh.X.dup;
		this.A=rh.A.dup;
		this.B=rh.B.dup;
		this.C=rh.C.dup;
		this.D=rh.D.dup;
	}

	Spline!T slice(T x1, T x2, T dx)
	{
		T[] x,y;
		for(auto t=x1; t <= x2; t+=dx) { x~=t; y~=opCall(t); }
		return spline(x,y);
	}

	Spline shift(T dx) {
		auto r=this;
		foreach(i; 0..N+1)
			r.X[i]+=dx;
		return r;
	}

	Range range(T dx) { return Range(this, dx); }
	private struct Range
	{
		private const Spline s;
		private T x, dx;

		this(ref const Spline s, T dx) {
			this.s=s;
			this.x=s.min;
			this.dx=dx;
		}
		bool empty() const { return x > s.max; }
		auto front() { return tuple!("x","y")(x, s(x)); }
		void popFront() { x+=dx; }
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