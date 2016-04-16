import post;
import local.getopt;
import local.spline;
import view;
import std.array;
import std.datetime;
import std.algorithm;
import std.stdio;


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
		if(all[id].start < 30)
			data.remove(id);
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
			foreach(id; post_id)
				data[id]=all[id];
		}
	}

	// find sum of all post views
	DateTime at=all.values.front.at;
	Post.Stat[DateTime] heap;
	// sum all view INCREMENTS int assoc.array by time
	foreach(id; all.keys) {
		uint last=0;
		at=min(at, all[id].at);
		foreach(stat; all[id].stat) {
			if(stat.ts !in heap)
				heap[stat.ts]=Post.Stat(stat.ts);
			heap[stat.ts].view+=stat.view-last;
			last=stat.view;
		}
	}
	// convert the array into Post.Stat[] array
	auto total=Post(0, at);
	foreach(ts; heap.keys.sort)
		total.add(heap[ts]);
	// convert view increments back to integral views
	uint last=0;
	foreach(ref stat; total.stat) {
		stat.view+=last;
		last=stat.view;
	}

	writeln("total ", total.at," +",total.start);
	double scale=total.stat.back.view;
	foreach(st; total.compress.range)
		writeln(st[0]/60.," ",st[1]/scale);
	writeln("pulse");
	auto tv=total.compress.view.smooth(1).normalize;
	for(double t=tv.start; t <= tv.end; t+=.1)
		writeln(t," ", tv(t)*20);
double w=0;
uint nw=0;
for(auto t=tv.start; t <= tv.end; t+=.1) { w+=tv(t); ++nw; }
w/=nw;
stderr.writeln("weight ",w);

	foreach(raw; data)
	{
		if(raw.start > 30) continue;
		if(raw.end < 1440) continue;
		auto post=raw.compress;
		double scale=post.stat.back.view;
		writeln("post ", post.id, " ", post.at);
		foreach(st; post.rebase(total).range)
			writeln(st[0]/60.," ",st[1]/scale);

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

	}

}