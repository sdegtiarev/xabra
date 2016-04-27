import std.stdio;
import std.array;
import std.container;
import std.conv;
import std.range;
import std.algorithm;
import std.datetime;
import std.traits;
import std.typecons;
import std.math;
import std.exception;;
import local.getopt;
import local.spline;
import post;
import view;



void main(string[] arg)
{
try {
	enum Field { id, length, at, start, duration, views };
	enum Mode { none, total, list, view, sum, raw };

	int mid=0, cid=0, cm=0, raw, position;
	bool log_scale, weighted;

	int[] post_id;
	Mode mode;
	Field[] fmt;
	Field sort_fn=Field.id;
	bool force_all, invert, average, normalize, weight, help;
	double avg_interval=0;
double FP=0;
	Option[] opt;
	getopt(opt, arg //,noThrow.yes
		, "-p|--post", "post id's to analyze. If not given, use entire file\nexcept truncated posts", &post_id
		, "-x|--exclude", "invert post list, exclude given list from the\nentire set", &invert
		, "-A|--all", "don't remove truncated posts", &force_all
		, "-t|--total", "display sum of all views (habrapulse)", delegate { mode=Mode.total; }
		, "-l|--list", "list posts according to the format or just post id's\nif empty", delegate { mode=Mode.list; }
		, "--format", "list format", &fmt
		, "--sort", "list sort field", &sort_fn
		, "-v|--view", "display selected posts views", delegate { mode=Mode.view; }
		, "-s|--sum", "sum selected posts views", delegate { mode=Mode.sum; }
		, "-r|--raw", "raw post data", delegate { mode=Mode.raw; }
		, "-S|--smooth", "average data on interval", delegate(double dt) { average=true; avg_interval=dt; }
		, "-N|--normalize", "normalize data", &normalize
		, "-W|--weight", "weight data", &weight
		, "-F", &FP
		//, "-v|--view", "show post view", delegate { mode=Mode.view; }
		//, "-a|--all", "views summary", delegate { mode=Mode.all; }
		//, "-x", "testing", delegate { mode=Mode.exp; }
		//, "-f", delegate { mode=Mode.fit; }
		//, "-r|--raw", "post raw views", &raw
		//, "-p|--position", "post position", &position
		//, "--format", "list format", &fmt
		//, "-n|--norm|--normalize", "normalize output", &normalize, true
		//, "-w|--weighted", &weighted
		//, "-i|--invert", &invert

		, "-h|-?|--help", "print this help", &help, true
	);
	if(help) {
		writeln("vue: analyze habrahabr statistics");
		writeln("Syntax: vue [OPTIONS | -h] [<file>]");
		writeln("  If no file given, read stdin");
		writeln("Options:\n",optionHelp(sort!("a.group < b.group || a.group == b.group && a.tag < b.tag")(opt)));
		writeln("Examples:");
		writeln("  vue -t post.list");
		writeln("  vue -txp100000,100013 post.list");
		writeln("  vue -lA --format=at,id,duration,length --sort=at");
		return;
	}

	File fd;
	if(arg.length < 2)
		fd.fdopen(0,"r");
	else
		fd.open(arg[1], "r");

	Post[uint] data, all=parse(fd);
	if(post_id.empty) {
		data=all.dup;
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
	if(!force_all) {
		foreach(post; data) {
			if(post.start > 30 || post.end < 1440)
				data.remove(post.id);
		}
	}
	enforce(data.length, "no valid posts");


	Post total=pulse(all.values).slice(data.values.interval);



	if(mode == Mode.total) {
		auto view=total.view;
		if(average) view=view.smooth(avg_interval);
		if(normalize) view=view.normalize;
		foreach(v; view.range(.1))
			writeln(v.x," ", v.y);
	
	} else if(mode == Mode.list) {
		if(fmt.empty)
			fmt~=Field.id;
		auto cmp=&Post.byId;
		switch(sort_fn) {
			case Field.id: cmp=&Post.byId; break;
			case Field.at: cmp=&Post.byAt; break;
			case Field.start: cmp=&Post.byStart; break;
			case Field.duration: cmp=&Post.byEnd; break;
			case Field.length: cmp=&Post.byLength; break;
			case Field.views: cmp=&Post.byViews; break;
			default: assert(0);
		}
		foreach(post; data.byValue.array.sort!cmp) {
			foreach(f; fmt)
			switch(f) {
				case Field.id: write(post.id, " "); break;
				case Field.at: write(post.at, " "); break;
				case Field.start: write(post.start, " "); break;
				case Field.duration: write(post.end, " "); break;
				case Field.length: write(post.length, " "); break;
				case Field.views: write(post.views, " "); break;
				default: assert(0);
			}
			writeln();
		}
	
	} else if(mode == Mode.view) {
		foreach(post; data) {
			View view;
			if(weight) {
				auto tv=total.view.smooth(4);
				view=post.compress.weight(tv);
			} else
				view=post.compress.view;
			if(average) view=view.smooth(avg_interval);
			if(normalize) view=view.normalize;
			writeln("post ",post.id," at ",post.at);
			foreach(v; view.range(.1))
				writeln(v.x," ", v.y);
		}

	} else if(mode == Mode.sum) {
		immutable double dt=.3;
		double[] x,y,w;
		uint n[];
		n.length=x.length=y.length=w.length=cast(uint) (200/dt);
		y[]=w[]=0;
		foreach(i; 0..x.length) x[i]=i*dt;
		auto tv=total.view.smooth(4);
		
		foreach(post; data) {
			auto view=post.compress.view;
			if(normalize) view=view.normalize;
			foreach(v; view.range(dt)) {
				uint i=cast(uint) (v.x/dt);
				assert(i >= 0, "negative index");
				assert(i < n.length, "huge index");
				++n[i];
				y[i]+=v.y;
				w[i]+=v.y/(tv(v.x)+FP);
			}
		}
		ulong end=n.length;
		while(n[end-1] == 0) --end;
		n.length=x.length=y.length=w.length=end;
		foreach(i; 0..n.length) {
			y[i]/=n[i];
			w[i]/=n[i];
		}

		auto sum=View(total.at, spline(x,y).S).normalize;
		writeln("summary");
		foreach(v; sum.range(.1))
			writeln(v.x," ",v.y);
		auto wgt=View(total.at, spline(x,w).S).normalize;
		writeln("weighted");
		foreach(v; wgt.range(.1))
			writeln(v.x," ",v.y);



	} else if(mode == Mode.raw) {
		foreach(post; data) {
			auto view=post.compress.view;
			if(average) view=view.smooth(avg_interval);
			if(normalize) view=view.normalize;
			writeln("at ",view.at);
			foreach(v; view.range(.1))
				writeln(v.x," ",v.y);

			auto tv=total.view.smooth(4);

			auto weighted=post.compress.weight(tv);
			if(average) weighted=weighted.smooth(avg_interval);
			if(normalize) weighted=weighted.normalize;
			double scale=normalize? 1 : 1e4;
			writeln("weighted");
			foreach(v; weighted.range(.1))
				writeln(v.x," ",v.y);

		}
	}


/+

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



