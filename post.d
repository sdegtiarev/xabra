module post;
import std.conv;
import std.range;
import std.algorithm;
import std.datetime;
import std.traits;
import std.typecons;
import std.exception;;
import local.spline;
import view;
import lview;
import core.stdc.math;
import std.stdio;




struct Post
{
	uint id;
	DateTime at;
	Stat[] stat;

	struct Stat
	{
		DateTime ts;
		uint view, mark, comm;
	}

	alias Interval=Tuple!(DateTime,"begin",DateTime,"end");

	@property auto empty() const { return stat.empty; }
	@property auto length() const { return stat.length; }
	@property auto begin() const { return stat.front.ts; }
	@property auto start() const { return (begin-at).total!"minutes"; }
	@property auto end() const { return (stat.back.ts-at).total!"minutes"; }
	@property auto views() const { return stat.back.view; }

	static bool byId(const ref Post a, const ref Post b) { return a.id < b.id; }
	static bool byAt(const ref Post a, const ref Post b) { return a.at < b.at; }
	static bool byStart(const ref Post a, const ref Post b) { return a.start < b.start; }
	static bool byEnd(const ref Post a, const ref Post b) { return a.end < b.end; }
	static bool byLength(const ref Post a, const ref Post b) { return a.length < b.length; }
	static bool byViews(const ref Post a, const ref Post b) { return a.views < b.views; }


	void add(DateTime t, uint v, uint m, uint c)
	{
		stat~=Stat(t,v,m,c);
	}
	void add(Stat s)
	{
		stat~=s;
	}

	auto range() {
		return zip(stat.map!(
			  a => (a.ts-at).total!"minutes")
			, stat.map!(a => a.view)
		);
	}

	Post compress() {
		auto r=Post(id,at);
		r.add(stat.front.ts,stat.front.view,0,0);
		foreach(s; stat) {
			if(s.view > r.stat.back.view) {
				r.add(s);
			}
		}
		if(stat.back.ts != r.stat.back.ts)
			r.add(stat.back);
		return r;
	}

	Post rebase(in Post to) {
		return Post(id,to.at,stat);
	}

	Post slice(T)(T interval)
	if(is(T == Interval))
	{
		size_t from, to;
		for(from=0; from < stat.length && stat[from+1].ts < interval[0]; ++from) {}
		for(to=stat.length; to > 0 && stat[to-1].ts > interval[1]; --to) {}
		return Post(id, stat[from].ts, stat[from..to]);
	}

	View view() {
		double[] x,y;
		foreach(s; stat) {
			x~=(s.ts-at).total!"minutes"/60.;
			y~=s.view;
		}
		return View(at, spline(x,y));
	}

	LView lview(D)(D dt)
	{
		//alias sample=lview.Stat;
		auto r=new LView();

		DateTime t=at;
		DateTime t0=at;
		float v0=0;
		r.insert(LStat(t0,v0));
		foreach(data; stat) {
			if(data.ts > t0) {
				double h=(data.ts-t0).total!"seconds";
				double dv=(data.view-v0)*3600./h;
				while(t <= data.ts) {
					double tau=(t-t0).total!"seconds"/h;
					r.insert(LStat(t,dv));
					t+=dt;
				}
			}
			t0=data.ts;
			v0=data.view;
		}
		return r;
	}

	View weight(const ref View w) {
		auto v0=this.view;
		double[]  x,y;
		double scale=0;
		uint cnt=0;
		foreach(n; v0.v.D1.nodes) {
			x~=n.x;
			auto wt=w(n.x);
			y~=n.a/wt;
			scale+=wt;
			++cnt;
		}
		scale/=cnt;
		foreach(ref v; y) v*=scale;
		return View(at, spline(x,y).S);
	}
}



Post[uint] parse(File fd)
{
	Post[uint] data;
	uint cnt=0;
	scope(exit) fd.close();

	foreach(line; fd.byLine)
	try {
		++cnt;
		auto p=parse(line);

		if(p.id !in data)
			data[p.id]=Post(p.id, p.at);
		data[p.id].add(p.ts, p.v, p.m, p.c);

	} catch(Exception err) {
		throw new Exception(("parse error at "~to!string(cnt)~": "~line).idup);
	}

	return data;
}




private auto parse(char[] line)
{
	auto t=line.split;
	enforce(t.length >= 6);
	return tuple!("id","at","ts","v","m","c") (
		  to!uint(t[1])
		, DateTime.fromISOExtString(t[2])
		, DateTime.fromISOExtString(t[0])
		, to!uint(t[3])
		, to!uint(t[4])
		, to!uint(t[5])
	);
}



Post.Interval interval(T)(T data)
if(is(ForeachType!T == Post))
{
	DateTime begin=data.front.begin;
	DateTime end=data.front.begin+dur!"minutes"(data.front.end);
	foreach(post; data) {
		begin=min(begin, post.at);
		end=max(end, post.begin+dur!"minutes"(post.end));
	}
	return Post.Interval(begin,end);
}
