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
import std.exception;
import std.format;
import local.getopt;
import post;
import view;

immutable auto dT=dur!"minutes"(10);
uint average=0;
bool weighted;

void main(string[] arg)
{
try {
	enum Field { id, length, at, start, duration, views };
	enum Mode { none, total, list, view, sum, raw, dev };

	int mid=0, cid=0, cm=0, raw, position;

	int[] post_id;
	Mode mode;
	Field[] fmt;
	Field sort_fn=Field.id;
	bool force_all, invert, normalize, help;
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
		, "-d|--dev", "under development", delegate { mode=Mode.dev; }
		, "-S|--smooth", "average data", &average
		, "-N|--normalize", "normalize data", &normalize
		, "-W|--weight", "weight data", &weighted

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


	//Post total=pulse(all.values).slice(data.values.interval);
	Post total=pulse(all.values);



	if(mode == Mode.total) {
		auto view=total.view(dT, total.at).smooth(average);
		if(normalize) view=view.normalize;
		writeln("from ",view.start," to ",view.end);
		foreach(v; view.range)
			writeln(v.time," ", v.value);
	
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
		auto tv=total.view(dT,total.at).smooth(50).normalize;
		foreach(post; data) {
			View view=post.view(dT,total.at).smooth(average);
			if(weighted) view=view.weight(tv);
			if(normalize) view=view.normalize;
			writeln("at ",post.at);
			//foreach(v; view.range(total.at))
			foreach(v; view.range)
				writeln(v.time," ", v.value);
		}



	} else if(mode == Mode.sum) {
		auto tv=total.view(dT,total.at).smooth(50).normalize;
		float[Duration] z;
		foreach(post; data) {
			View view=post.view(dT,total.at);
			if(weighted) view=view.weight(tv);
			if(normalize) view=view.normalize;
			auto t0=view.start;
			foreach(v; view.range) {
				auto t=v.ts-t0;
				if(t !in z) z[t]=0;
				z[t]+=v.value;
			}
		}
		auto s=new View;
		foreach(v; z.byKeyValue)
			s.add(total.at+v.key, v.value);
		s=s.smooth(average).normalize;
		writeln(" ");
		foreach(v; s.range)
			writeln(v.time," ", v.value);
			//if(v.value > .1) writeln(v.time," ", log(v.value));




	} else if(mode == Mode.dev) {
		auto tv=total.view(dT,total.at).smooth(50).normalize;
		foreach(post; data) {
			View base=post.view(dT, total.at).smooth(average);
			if(weighted) base=base.weight(tv);
			base=base.normalize;
			foreach(sample; data) {
				if(sample.id >= post.id)
					continue;
				View view=sample.view(dT,total.at).smooth(average);
				if(weighted) view=view.weight(tv);
				view=view.normalize;
				auto f=fit(base, view);
				writeln(sample.id," ",post.id," ",f);
				writeln(post.id," ",sample.id," ",f);

			}
		}

	} else if(mode == Mode.raw) {
		foreach(post; data) {
			writeln("post ",post.id);	
			foreach(v; post.range)
				writeln(v[0]/60.," ",v[1]);
			writeln("");	
			foreach(v; post.compress.range)
				writeln(v[0]/60.," ",v[1]);
		}
	}





} catch(Exception x) {
	writefln(x.msg);
}
}


auto fit(View base, View view)
{
	double f0=0, f1=0, f2=0;
	foreach(v; zip(base.range, view.range)) {
		f0+=v[0].value*v[0].value;
		f1+=v[0].value*v[1].value;
		f2+=v[1].value*v[1].value;
	}
	auto k=f1/f2;
	double fit=0;
	uint n=0;
	foreach(v; zip(base.range, view.range)) {
		auto f=v[0].value-k*v[1].value;
		fit+=f*f;
		++n;
	}
	fit=sqrt(fit/f0);
	return fit;
}

auto fit0(View base, View view)
{
	double f0=0, f1=0;
	foreach(v; zip(base.range, view.range)) {
		auto f=v[0].value-v[1].value;
		f1+=f*f;
		f0+=v[0].value*v[0].value;
	}
	return sqrt(f1/f0);
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




/*
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
*/









/*
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
*/


