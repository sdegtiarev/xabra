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
import core.stdc.math;
import local.getopt;
import local.spline;
import post;
import view;



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
		, "-x|--exclude", "invert post id's list", &invert
		, "-l|--list", "list posts", &list, true
		, "-t|--total", "display sum of all views", &show_total, true
		//, "-v|--view", "show post view", delegate { mode=Mode.view; }
		//, "-a|--all", "views summary", delegate { mode=Mode.all; }
		//, "-x", "testing", delegate { mode=Mode.exp; }
		//, "-f", delegate { mode=Mode.fit; }
		//, "-r|--raw", "post raw views", &raw
		//, "-p|--position", "post position", &position
		//, "--format", "list format", &fmt
		//, "--sort", "list sort field", &sort_fn
		//, "-n|--norm|--normalize", "normalize output", &normalize, true
		//, "-w|--weighted", &weighted
		//, "-i|--invert", &invert

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

	Post[uint] data, all=parse(fd);
	if(post_id.empty) {
		data=all;
	} else {
		if(invert) {
			data=all;
			foreach(id; post_id)
				data.remove(id);
		} else {
			foreach(id; post_id) {
				if(id in all)
					data[id]=all[id];
				else
					stderr.writeln("post ",id," ignored");
			}
		}
	}

	Post total=pulse(all.values);
	auto tv=total.view.normalize;
	foreach(v; tv.range(.1))
			writeln(v.x," ", v.y*20);

/+
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

+/



} catch(Exception x) {
	writefln(x.msg);
}
}




Post pulse(T)(T data)
if(is(ForeachType!T == Post))
{
	// find sum of all post views
	DateTime at=data.front.at;

	Post.Stat[DateTime] heap;
	// sum all post INCREMENTS into assoc.array indexed by time
	foreach(post; data) {
		uint last=0;
		at=min(at, post.at);
		foreach(stat; post.stat) {
			if(stat.ts !in heap)
				heap[stat.ts]=Post.Stat(stat.ts);
			heap[stat.ts].view+=stat.view-last;
			last=stat.view;
		}
	}

	// convert the array into Post.Stat[] array
	auto pulse=Post(0, at);
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
