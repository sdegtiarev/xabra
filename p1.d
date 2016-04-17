import post;
import local.getopt;
import local.spline;
import view;
import std.array;
import std.datetime;
import std.algorithm;
import std.traits;
import std.stdio;

immutable bool STAGE1=true;

void main(string[] arg)
{
	bool help, invert;
	int[] post_id;
	getopt(arg
		, "-p|--post", "post id's to analyze", &post_id
		, "-i|--invert", "invert post list", &invert
		, "-h|-?|--help", "print this help", &help, true
	);


	File fd;
	if(arg.length < 2)
		fd.fdopen(0,"r");
	else
		fd.open(arg[1], "r");

	Post[uint] data, all=parse(fd);
	// get rid of post tails
	foreach(id; all.keys) {
		if(all[id].start > 30)
			all.remove(id);
	}
	// select posts according to command line list
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

	if(STAGE1) 
	{
		writeln("total views");
		foreach(v; tv.S(.1)) {
			if(v.x > 100) break;
			writeln(v.x," ", v.y);
		}
		writeln("habapulse");
		foreach(v; tv.range(.1)) {
			if(v.x > 100) break;
			writeln(v.x," ", v.y*20);
		}

		foreach(raw; data.values.sort!byAt) {
			if(raw.start > 30) continue;
			if(raw.end < 1440) continue;
			auto post=raw.rebase(total).compress.view.normalize;
			writeln("at ", raw.at);
			foreach(v; post.S(.1))
				writeln(v.x," ", v.y);

			writeln();
			foreach(v; post.range(.1))
				writeln(v.x," ", v.y);

		}
	}
/*
		writeln("view");
		auto pv=post.rebase(total).view.normalize;
		for(double t=pv.start; t <= pv.end; t+=.1)
			writeln(t," ", pv(t)*6);

		writeln("integrated");
		double[] x,y;
		for(double t=pv.start; t <= pv.end; t+=.1) {
			x~=t;
			y~=pv(t)/(tv(t)+w/20);
		}
		auto iv=View(pv.at, spline(x,y));
		scale=iv.v.S(iv.end);
		for(double t=iv.start; t <= iv.end; t+=.1)
			writeln(t," ", iv.v.S(t)/scale);

		writeln("weighted");
		double[] xw,yw;
		for(double t=iv.start; t <= iv.end; t+=.1) {
			xw~=t;
			yw~=iv.v.S(t)/scale;
		}
		auto wv=View(pv.at, spline(xw,yw));
		for(double t=wv.start; t <= wv.end; t+=.1)
			writeln(t," ", wv(t)*6);
*/

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
