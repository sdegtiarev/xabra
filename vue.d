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
	//static immutable auto epoch=DateTime(1970, 1, 1)+dur!"hours"(3);

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
	@property auto start() const { return _stat.front.ts; }
	@property auto end() const { return _stat.back.ts; }
	@property auto max() const { return _stat.back.view; }

	static bool byId(Post a, Post b) { return a.id < b.id; }
	static bool byAt(Post a, Post b) { return a.at < b.at; }
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
		return View(at, spline!float(vx,vy));
	}
}

struct View
{
	DateTime at;
	Spline!float v;

	this(DateTime at, Spline!float sp) { this.at=at; this.v=sp; }

	@property float start() const { return v.min; }
	@property float end()   const { return v.max; }
	float opCall(float t)   const { return v.der1(t); }
}



void main(string[] arg)
{
try {
	enum Field { id, length, at, begin, end,
		total_view, total_mark, total_comment,
		max_view, max_mark, max_comment
	};
	enum Mode { none, view, all, exp };

	int id=0, mid=0, cid=0, cm=0, raw, position, skip;
	bool list, show_total, help, log_scale;
	Mode mode;
	Field[] fmt;
	Field sort_fn=Field.id;
	Option[] opt;
	getopt(opt, arg //,noThrow.yes
		, "-t|--total", "display sum of all views", &show_total, true
		, "-l|--list", "list posts", &list, true
		, "-v|--view", "post views", delegate(string arg) { id=to!uint(arg); mode= Mode.view; }
		, "-a|--all", "views summary", delegate { mode= Mode.all; }
		, "-r|--raw", "post raw views", &raw
		, "-p|--position", "post position", &position
		, "--format", "list format", &fmt
		, "--sort", "list sort field", &sort_fn
		, "--skip", "drop posts started later than the limit", &skip
		, "-x", "testing", delegate(string arg) { id=to!uint(arg); mode=Mode.exp; }
		//, "-p|--post", &id
		//, "-L|--log", &log_scale
		//, "-l|--list", &list
		//, "-g|--gap", &gap
		//, "-t|--total", &show_
		//, "-m|--mark", &mid
		//, "-c|--comment", &cid
		////, "r", &cm
		//, "-r|--raw", &raw
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


	// list posts
	if(list) {
		if(fmt.empty)
			fmt~=Field.id;
		auto cmp=&Post.byId;
		switch(sort_fn) {
			case Field.id: cmp=&Post.byId; break;
			case Field.at: cmp=&Post.byAt; break;
			case Field.length: cmp=&Post.byLength; break;
			default: assert(0);
		}
		foreach(post; data.byValue.array.sort!cmp) {
		//if(skip && (post.begin-post.at).total!"minutes" > skip)
		//	continue;
			foreach(f; fmt)
			switch(f) {
				case Field.id: write(post.id, " "); break;
				case Field.at: write(post.at, " "); break;
				case Field.begin: write(post.begin, " "); break;
				case Field.end: write(post.end, " "); break;
				case Field.length: write(post.length, " "); break;
				default: assert(0);
			}
			writeln();
		}
	}

	if(show_total) {
		auto total=total(data);
		for(auto t=total.start; t < total.end; t+=.25)
			writeln(t," ",total(t));
		writeln("smooth 1hr");
		auto s1=smooth(total.v,1);
		for(auto t=s1.min; t < s1.max; t+=.25)
			writeln(t," ",s1.der1(t));
		writeln("smooth 2hr");
		auto s2=smooth(total.v,2);
		for(auto t=s2.min; t < s2.max; t+=.25)
			writeln(t," ",s2.der1(t));
	}


	if(id && mode == Mode.view) {
		auto total=total(data);
		auto weight=total.v.smooth(2);
		auto view=data[id].view;
		auto t0=hr(total.at,view.at);

		writeln("post ", id);
		//for(auto t=view.start; t < view.end; t+=.5)
		//	writeln(t," ",view(t));
		//writeln("weighted");
		for(auto t=view.start; t < view.end; t+=.5)
			writeln(t," ",view(t)/weight(t+t0));
	}


	if(mode == Mode.all) {
		auto av=average(data);
		for(float t=av.start; t < av.end; t+=.1)
			writeln(t," ",av(t));
	}

	if(mode == Mode.exp) {
		auto total=total(data);
		auto weight=total.v.smooth(2);
		auto view=data[id].view;
		auto av=average(data);
		auto t0=hr(total.at,view.at);

		writeln("post ", id);
		for(auto t=max(view.start, av.start) ; t < view.end && t < av.end; t+=.1) {
			writeln(av(t), view(t)/weight(t+t0));
		}

	}



/*
	if(id) {
		auto post=data[id];
		auto t0=post.at;
		float[DateTime] dv;
		foreach(stat; post.hist_) 
			dv[stat.ts]=stat.dv;

		writeln("post ",post.id);
		foreach(ts; dv.keys.sort)
			writeln((ts-t0).total!"seconds"/3600.," ",dv[ts]);
	}

	if(raw) {
		id=raw;
		auto post=data[id];
		static if(0) {
			DateTime t0=post.at.date;
		} else {
			DateTime t0=post.at.date;
			foreach(p; data)
				t0=min(t0, DateTime(p.begin.date));
		}
		float[DateTime] dv;
		foreach(stat; post.hist_) 
			dv[stat.ts]=stat.view;

		writeln("post ",post.id);
		foreach(ts; dv.keys.sort)
			writeln((ts-t0).show_total!"seconds"/3600.," ",dv[ts]);

		double[] t=post.hist_.array.map!(a => (a.ts-t0).total!"minutes"/60.).array;
		double[] v=post.hist_.array.map!(a => cast(double) a.view).array;
		auto s=spline(t,v);
		writeln("spline");
		for(double dt=s.min; dt <=s.max; dt+=.2)
			writeln(dt, " ", s.der1(dt));

	}

	if(position) {
		id=position;
		auto post=data[id];
		auto t0=post.at;
		float[DateTime] dv;
		foreach(stat; post.hist_) 
			dv[stat.ts]=stat.pos;

		writeln("post ",post);
		foreach(ts; dv.keys.sort)
			writeln((ts-t0).show_total!"seconds"/3600.," ",dv[ts]);
	}



	if(mid) {
		float[DateTime] sum=average(total_views(data));
		auto post=data[mid];
		auto t0=post.at;
		float[DateTime] dm;
		foreach(stat; post.hist_)
			dm[stat.ts]=stat.dm;
		auto sdm=average(dm);

		writeln("post ",post);
		foreach(t; dm.keys.sort)
		if(sum[t] > 0) {
			auto ts=(t-t0).total!"seconds"/3600.;
			if(log_scale && sdm[t] > 0)
				writeln(ts," ",log(sdm[t]/sum[t]));
			else
				writeln(ts," ",sdm[t]/sum[t]);
		}
	}


	if(cid) {
		float[DateTime] sum=average(total_views(data));
		auto post=data[cid];
		auto t0=post.at;
		float[DateTime] dc;
		foreach(stat; post.hist_)
			dc[stat.ts]=stat.dc;
		auto sdc=average(dc);

		writeln("post ",post);
		foreach(t; dc.keys.sort)
		if(sum[t] > 0) {
			auto ts=(t-t0).show_total!"seconds"/3600.;
			if(log_scale && sdc[t] > 0)
				writeln(ts," ",log(sdc[t]/sum[t]));
			else
				writeln(ts," ",sdc[t]/sum[t]);
		}
	}

	if(cm) {
		auto post=data[cm];
		writeln("post ",post);
		foreach(stat; post.hist_) {
			if(stat.view == 0 || stat.mark == 0 || stat.comm == 0)
				continue;
			float view=stat.view;
			if(log_scale)
				writeln(log(stat.mark/view)," ",log(stat.comm/view));
			else
				writeln(stat.mark/view," ",stat.comm/view);
		}

	}
*/

} catch(Exception x) {
	writefln(x.msg);
}
}


View total(T)(T data)
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
foreach(i; 1..total._stat.length)
	total._stat[i].view+=total._stat[i-1].view;
	total._at=DateTime(total.begin.date);
	return total.view;
}


View average(T)(T data)
if(is(ForeachType!T == Post))
{
	auto total=total(data);
	auto smt=total.v.smooth(2);

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
				vy+=v(t)/smt(t+t0);
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



Spline!T smooth(T)(Spline!T s, float dt)
{
	float[] x, y;
	for(float t=s.min; t < s.max; t+=dt) {
		x~=t;
		y~=s(t);
	}
	x~=s.max;
	y~=s(s.max-dt*1e-6);

	return spline(x,y);
}