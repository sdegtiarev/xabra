import std.stdio;
import std.array;
import std.container;
import std.conv;
import std.range;
import std.algorithm;
import std.datetime;
import std.traits;
import std.typecons;
import std.exception;;
import local.getopt;
import local.spline;
import core.stdc.math;

struct Post
{
	uint _id;
	DateTime _at;
	Stat[] _stat;

	struct Stat
	{
		DateTime ts;
		uint view, mark, comm, pos;
	}

	@property auto id() const { return _id; }
	@property auto empty() const { return _stat.empty; }
	@property auto length() const { return _stat.length; }
	@property auto at() const { return _at; }
	@property auto begin() const { return _stat.front.ts; }
	@property auto start() const { return hr(at, _stat.front.ts); }
	@property auto end() const { return hr(at, _stat.back.ts); }
	@property auto max() const { return _stat.back.view; }

	static bool byId(Post a, Post b) { return a.id < b.id; }
	static bool byAt(Post a, Post b) { return a.at < b.at; }
	static bool byStart(Post a, Post b) { return a.start < b.start; }
	static bool byEnd(Post a, Post b) { return a.end < b.end; }
	static bool byLength(Post a, Post b) { return a.length < b.length; }


	void add(DateTime t, uint v, uint m, uint c, uint p)
	{
		_stat~=Stat(t,v,m,c,p);
	}
	void add(Stat s)
	{
		_stat~=s;
	}

	string toString() {
		return to!string(this.id)~" "~to!string(this.at)~" "~to!string(this.length);
	}

	View view() const
	{
		float[] vx,vy;
		foreach(stat; _stat) {
			if(!vy.empty && stat.view == vy.back)
				continue;
			vx~=hr(at,stat.ts);
			vy~=stat.view;
		}
		return View(at, spline(vx,vy));
	}
	View norm() const
	{
		float[] vx,vy;
		float max=_stat.back.view, last;
		foreach(stat; _stat) {
			if(!vy.empty && stat.view == last)
				continue;
			vx~=hr(at,stat.ts);
			vy~=stat.view/max;
			last=stat.view;
		}
		return View(at, spline(vx,vy));
	}
}

struct View
{
	DateTime at;
	Spline!float v;

	this(DateTime at, Spline!float sp) { this.at=at; this.v=sp; }

	@property float start() const { return v.min; }
	@property float end()   const { return v.max; }
	float opCall(float t)   const { return v.D1(t); }

	View smooth(float dx) {
		float[] x,y;
		x~=v.min;
		y~=v(v.min);
		for(float t=v.min+dx/2; t < (v.max-dx/2); t+=dx) {
			x~=t;
			y~=(v(t-dx/2)+v(t)+v(t+dx/2))/3;
		}
		x~=v.max;
		y~=v(v.max);
		return View(at,spline!float(x,y));
	}
	View norm() const
	{
		float scale=v(v.max);
		auto s=spline(v);
		s/=scale;
		return View(at, s);
	}
}



void main(string[] arg)
{
try {
	enum Field { id, length, at, start, end };
	enum Mode { none, view, all, fit, exp };

	int mid=0, cid=0, cm=0, raw, position;
	int[] post_id;
	bool list, show_total, help, log_scale, normalize, weighted, invert;
	Mode mode;
	Field[] fmt;
	Field sort_fn=Field.id;
	Option[] opt;
	getopt(opt, arg //,noThrow.yes
		, "-p|--post", "post id's to analyze", &post_id
		, "-l|--list", "list posts", &list, true
		, "-t|--total", "display sum of all views", &show_total, true
		, "-v|--view", "post views", delegate { mode=Mode.view; }
		, "-a|--all", "views summary", delegate { mode=Mode.all; }
		, "-x", "testing", delegate { mode=Mode.exp; }
		, "-f", delegate { mode=Mode.fit; }
		, "-r|--raw", "post raw views", &raw
		, "-p|--position", "post position", &position
		, "--format", "list format", &fmt
		, "--sort", "list sort field", &sort_fn
		, "-n|--norm|--normalize", "normalize output", &normalize, true
		, "-w|--weighted", &weighted
		, "-i|--invert", &invert

		, "-h|-?|--help", "print this help", &help, true
	);
	if(help) {
		writeln("vue: analyze habrahabr statistics");
		writeln("Syntax: vue [-t] [-l] [-h] <file>");
		writeln("Options:\n",optionHelp(sort!("a.group < b.group || a.group == b.group && a.tag < b.tag")(opt)));
		return;
	}

	File fd;
	if(arg.length < 2)
		fd.fdopen(0,"r");
	else
		fd.open(arg[1], "r");

	auto data=parse(fd);
	if(!post_id.empty) {
		if(invert) {
			foreach(id; post_id)
				data.remove(id);
		} else {
			Post[uint] inv=data.dup;
			foreach(id; post_id)
				inv.remove(id);
			foreach(id; keys(inv))
				data.remove(id);
		}
	}


	// list posts
	if(list) {
		if(fmt.empty)
			fmt~=Field.id;
		auto cmp=&Post.byId;
		switch(sort_fn) {
			case Field.id: cmp=&Post.byId; break;
			case Field.at: cmp=&Post.byAt; break;
			case Field.start: cmp=&Post.byStart; break;
			case Field.end: cmp=&Post.byEnd; break;
			case Field.length: cmp=&Post.byLength; break;
			default: assert(0);
		}
		foreach(post; data.byValue.array.sort!cmp) {
			foreach(f; fmt)
			switch(f) {
				case Field.id: write(post.id, " "); break;
				case Field.at: write(post.at, " "); break;
				case Field.start: write(post.start, " "); break;
				case Field.end: write(post.end, " "); break;
				case Field.length: write(post.length, " "); break;
				default: assert(0);
			}
			writeln();
		}
	}

	if(show_total) {
		auto total=total(data).view.smooth(2);
		writeln("smooth 2hr");

		for(auto t=total.start; t < total.end; t+=.25)
			writeln(t," ",total(t));
	}


	if(mode == Mode.view)
	foreach(id; post_id) {
		auto total=total(data).view.smooth(2);
		auto view=data[id].view;
		auto t0=hr(total.at,view.at);

		writeln("post ", id);
		for(auto t=view.start; t < view.end && (t+t0) < total.end; t+=.1)
			writeln(t," ",view(t)/total(t+t0));
	}

	if(mode == Mode.exp)
	foreach(id; post_id) {
		auto total=total(data).norm.smooth(1);
		auto view=data[id].norm;
		//auto view=data[id].view;
		auto t0=hr(total.at,view.at);
		auto smot=view.smooth(1);

		writeln("post ",id," ",data[id].at);
		for(auto t=view.start; t <= view.end; t+=.1)
			writeln(t+data[id].at.hour," ",view(t)," ",smot(t));

		writeln("weighted");
		for(auto t=view.start; t <= view.end; t+=.1)
			writeln(t+data[id].at.hour," ",smot(t)/total(t+t0)/100);

	}


	if(mode == Mode.all) {
		auto av=normalize? average(data, weighted).norm : average(data, weighted);
		for(float t=av.start; t < av.end; t+=.1)
			writeln(t," ",av(t));
	}

	if(mode == Mode.fit) {

		auto av=normalize? average(data, weighted).norm : average(data, weighted);
		foreach(id; post_id) {
			auto view=data[id].view.smooth(1);
			auto start=max(view.start,av.start);
			auto end=min(view.end,av.end);
			auto sc=fit(view, av);
			view.v*=sc;
writeln(cast(uint) (diff(view, av)*100)," ",id);
//writeln("fit ", cast(uint) (diff(view, av)*100),"%");
//			for(auto t=start; t < end; t+=.1)
//				writeln(t," ",view(t)," ",av(t));
		}
	}





} catch(Exception x) {
	writefln(x.msg);
}
}


Post total(T)(T data)
if(is(ForeachType!T == Post))
{
	Post.Stat[DateTime] heap;
	foreach(post; data) {
		auto stat=post._stat;
		foreach(i; 0..post.length-1) {
			auto t0=stat[i].ts, t1=stat[i+1].ts;
			if(t0 !in heap)
				heap[t0]=Post.Stat(t0);
			heap[t0].view+=stat[i+1].view-stat[i].view;
			heap[t0].mark+=stat[i+1].mark-stat[i].mark;
			heap[t0].comm+=stat[i+1].comm-stat[i].comm;
		}
	}

	Post total;
	foreach(ts; heap.keys.sort)
		total.add(heap[ts]);
writeln("raw total");
foreach(st; total._stat)
writeln(hr(DateTime(total.begin.date),st.ts)," ",st.view);
	foreach(i; 1..total._stat.length)
		total._stat[i].view+=total._stat[i-1].view;
	total._at=DateTime(total.begin.date);
	return total;
}





Post[uint] parse(File fd)
{
	Post[uint] data;
	uint[DateTime] position;
	uint cnt=0;
	scope(exit) fd.close();

	foreach(line; fd.byLine) {
	try {
		++cnt;
		auto p=parse(line);

		if(p.ts !in position)
			position[p.ts]=0;
		++position[p.ts];

		if(p.id !in data)
			data[p.id]=Post(p.id, p.at);
		data[p.id].add(p.ts, p.v, p.m, p.c, position[p.ts]);

	} catch(Exception err) {
		throw new Exception(("parse error at "~to!string(cnt)~": "~line).idup);
	}
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


float hr(DateTime start, DateTime end)
{
	return (end-start).total!"minutes"/60.;
}



View average(T)(T data, bool weight)
if(is(ForeachType!T == Post))
{
	auto total=total(data).view.smooth(2);

	View[] view;
	DateTime at=Date(3000,1,1);
	foreach(post; data) {
		if(post.length < 10 || hr(post.at, post.begin) > .5)
			continue;
		view~=post.view;
		at=min(at, view.back.at);
	}
	
	float[] x, y;
	for(float t=0; t < total.end; t+=.5) {
		float vy=0;
		uint n=0;
		foreach(v; view) {
			auto t0=hr(total.at, v.at);
			if(t > v.start && t < v.end && (t+t0) < total.end) {
				vy+=weight? v(t)/total(t+t0) : v(t);
				++n;
			}
		}
		if(n) {
			x~=t;
			y~=vy/n;
		}
	}
	foreach(i; 1..y.length)
		y[i]+=y[i-1];

	return View(at, spline(x,y));
}


auto fit(View a, View b)
{
	auto start=max(a.start,b.start);
	auto end=min(a.end,b.end);
	float A=0, F=0;
	for(auto t=start; t < end; t+=.5) {
		auto x=a(t), y=b(t);
		A+=x*x;
		F+=x*y;
	}
	return F/A;
}

auto diff(View a, View b)
{
	auto start=max(a.start,b.start);
	auto end=min(a.end,b.end);
	float s=0, z=0;
	for(auto t=start; t < end; t+=.5) {
		auto x=a(t), y=b(t);
		s+=(x-y)*(x-y);
		z+=y*y;
	}
	return sqrt(s/z);
}
