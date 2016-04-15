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
import core.stdc.math;
import std.stdio;


bool byId(const ref Post a, const ref Post b) { return a.id < b.id; }
bool byAt(const ref Post a, const ref Post b) { return a.at < b.at; }
bool byStart(const ref Post a, const ref Post b) { return a.start < b.start; }
bool byEnd(const ref Post a, const ref Post b) { return a.end < b.end; }
bool byLength(const ref Post a, const ref Post b) { return a.length < b.length; }


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

	@property auto empty() const { return stat.empty; }
	@property auto length() const { return stat.length; }
	@property auto begin() const { return stat.front.ts; }
	@property auto start() const { return (begin-at).total!"minutes"; }
	@property auto end() const { return (stat.back.ts-at).total!"minutes"; }
	@property auto max() const { return stat.back.view; }

	void add(DateTime t, uint v, uint m, uint c)
	{
		stat~=Stat(t,v,m,c);
	}
	void add(Stat s)
	{
		stat~=s;
	}

	auto range() { return zip(stat.map!(a => (a.ts-at).total!"minutes"), stat.map!(a => a.view)); }

	Post compress() {
		auto r=Post(id,at);
		r.add(stat.front.ts,stat.front.view,0,0);
		foreach(s; stat) {
			if(s.view > r.stat.back.view) {
				r.add(s);
			}
		}
		return r;
	}


	View view() const {
		double[] x,y;
		foreach(st; stat) {
			x~=(st.ts-at).total!"minutes"/60.;
			y~=st.view;
		}
		return View(at, spline(x,y));
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




auto parse(char[] line)
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

