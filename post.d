module post;
import std.conv;
import std.range;
import std.algorithm;
import std.datetime;
import std.traits;
import std.typecons;
import std.exception;;
import std.regex;;
import view;
import std.stdio;




struct Post
{
	uint id;
	DateTime at;
	string type;
	string[] hub;
	Stat[] stat;

	struct Stat
	{
		DateTime ts;
		uint view, plus, minus, mark, comm;
	}

	alias Interval=Tuple!(DateTime,"begin",DateTime,"end");

	@property auto empty() const { return stat.empty; }
	@property auto length() const { return stat.length; }
	@property auto begin() const { return stat.front.ts; }
	@property auto start() const { return (begin-at).total!"minutes"; }
	@property auto end() const { return (stat.back.ts-at).total!"minutes"; }
	@property auto views() const { return stat.back.view; }
	@property auto marks() const { return stat.back.mark; }
	@property auto comms() const { return stat.back.comm; }

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
		return Post(id, to.at, to.type, to.hub.dup, stat);
	}

	Post slice(T)(T interval)
	if(is(T == Interval))
	{
		size_t from, to;
		for(from=0; from < stat.length && stat[from+1].ts < interval[0]; ++from) {}
		for(to=stat.length; to > 0 && stat[to-1].ts > interval[1]; --to) {}
		return Post(id, stat[from].ts, stat[from..to]);
	}

	View view(D)(D dt, DateTime t0)
	{
		auto r=new View;

		while(t0 > at) t0-=dt;
		while(t0 <= begin) t0+=dt;
		//t0-=dt;
		DateTime t=t0;
		float v0=stat.front.view;
		foreach(data; this.compress.stat) {
			if(data.ts > t0) {
				double h=(data.ts-t0).total!"seconds"/3600.;
				double dv=(data.view-v0)/h;
				while(t <= data.ts) {
					r.add(t,dv);
					t+=dt;
				}
			}
			t0=data.ts;
			v0=data.view;
		}
		return r;
	}


	View mark(D)(D dt, DateTime t0)
	{
		auto r=new View;

		while(t0 > at) t0-=dt;
		while(t0 <= begin) t0+=dt;
		DateTime t=t0;
		float v0=stat.front.mark;
		foreach(data; this.compress.stat) {
			if(data.ts > t0) {
				double h=(data.ts-t0).total!"seconds"/3600.;
				double dv=(data.mark-v0)/h;
				while(t <= data.ts) {
					r.add(t,dv);
					t+=dt;
				}
			}
			t0=data.ts;
			v0=data.mark;
		}
		return r;
	}

	View mark(D)(D dt, Post wt)
	{
		auto r=new View;

		DateTime t0=wt.at;
		while(t0 > at) t0-=dt;
		while(t0 <= begin) t0+=dt;
		DateTime t=t0;
		float[DateTime] w0; foreach(st; wt.stat) w0[st.ts]=st.view;

		float v0=stat.front.mark/w0[stat.front.ts];
		//float v0=stat.front.mark;
		foreach(data; this.compress.stat) {
			if(data.ts > t0) {
				double h=(data.ts-t0).total!"seconds"/3600.;
				double dv=(data.mark/w0[data.ts]-v0)/h;
				//double dv=(data.mark-v0)/h;
				while(t <= data.ts) {
					r.add(t,max(dv,0));
					t+=dt;
				}
			}
			t0=data.ts;
			v0=data.mark/w0[data.ts];
			//v0=data.mark;
		}
		return r;
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
		throw new Exception((to!string(err.message)~": parse error at "~to!string(cnt)~": "~line).idup);
	}

	return data;
}




private auto parse(char[] line)
{
	auto r=matchFirst(line, ctRegex!"#(\\w*)\\s\\[(.*)\\]");
	auto type=r[1];
	auto u=matchAll(r[2], ctRegex!"\"(.*?)\"");
	string[] hubs;
	foreach(ref uu; u) hubs~=uu[1].idup;
	auto t=r.pre.split;
	writeln(t[0], " ", type, ": ", hubs);
	enforce(t.length >= 8);
	//return tuple!("id","at","ts","v","p","n","c","m", "t", "h") (
	return tuple!("id","at","ts","v","p","n","c","m") (
		  to!uint(t[0])
		, DateTime.fromISOExtString(t[1])
		, DateTime.fromISOExtString(t[2])
		, to!uint(t[3])
		, to!uint(t[4])
		, to!uint(t[5])
		, to!uint(t[6])
		, to!uint(t[7])
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



Post sum(T)(T data)
if(is(ForeachType!T == Post))
{
	// find sum of all post views
	DateTime at=data.front.begin;

	Post.Stat[DateTime] heap;
	// sum all post INCREMENTS into assoc.array indexed by time
	foreach(post; data) {
		uint last=0;
		at=min(at, post.begin);
		foreach(stat; post.stat) {
			if(stat.ts !in heap)
				heap[stat.ts]=Post.Stat(stat.ts);
			heap[stat.ts].view+=stat.view-last;
			last=stat.view;
		}
	}

	// convert the array into Post.Stat[] array
	auto pulse=Post(0, DateTime(at.date));
	foreach(ts; heap.keys.sort)
		pulse.add(heap[ts]);

	// convert view increments back to integral views
	uint last=0;
	foreach(ref stat; pulse.stat) {
		stat.view+=last;
		last=stat.view;
	}
	return pulse.compress;
}
