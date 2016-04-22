import post;
import local.getopt;
import local.spline;
import view;
import std.array;
import std.datetime;
import std.algorithm;
import std.math;
import std.traits;
import std.stdio;



void main(string[] arg)
{
	bool help, invert;
	int[] post_id;
	int STAGE=0;
	getopt(arg
		, "-p|--post", "post id's to analyze", &post_id
		, "-i|--invert", "invert post list", &invert
		, "--stage", &STAGE
		, "-h|-?|--help", "print this help", &help, true
	);


	File fd;
	if(arg.length < 2)
		fd.fdopen(0,"r");
	else
		fd.open(arg[1], "r");

	Post[uint] data, all=parse(fd);
	//// get rid of post tails
	//foreach(id; all.keys) {
	//	if(all[id].start > 30)
	//		all.remove(id);
	//}
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

	if(STAGE == 1) 
	{
		writeln("total views");
		foreach(v; tv.S(.1)) {
			if(v.x > 150) break;
			writeln(v.x," ", v.y);
		}
		writeln("habapulse");
		foreach(v; tv.range(.1)) {
			if(v.x > 150) break;
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

	if(STAGE == 2) {
		writeln("total views");
		foreach(v; tv.S(.1)) {
			if(v.x > 150) break;
			writeln(v.x," ", v.y);
		}
		writeln();
		foreach(v; tv.range(.1)) {
			if(v.x > 150) break;
			writeln(v.x," ", v.y*20);
		}

		// average weight
		uint n=0;
		double w=0;
		foreach(v; tv.range(.5)) { w+=v.y; ++n; }
		tv.v/=w/n;

		foreach(raw; data.values.sort!byAt) {
			auto post=raw.rebase(total).compress.view.normalize;
			//writeln("at ", raw.at," views ",raw.max);
			writefln("tension %-5.2s",post.tension);
			foreach(v; post.S(.1))
				writeln(v.x," ", v.y);

			writefln("tension %-5.2s",weight(post, tv, .0).tension);
			foreach(v; weight(post, tv, .0).S(.1))
				writeln(v.x," ", v.y);

			writefln("tension %-5.2s",weight(post, tv, .2).tension);
			foreach(v; weight(post, tv, .2).S(.1))
				writeln(v.x," ", v.y);

			writefln("tension %-5.2s",weight(post, tv, .4).tension);
			foreach(v; weight(post, tv, .4).S(.1))
				writeln(v.x," ", v.y);

			writefln("tension %-5.2s",weight(post, tv, .6).tension);
			foreach(v; weight(post, tv, .6).S(.1))
				writeln(v.x," ", v.y);
		}

	}

	if(STAGE == 3) {
		writeln();
		foreach(v; tv.range(.1)) {
			if(v.x > 150) break;
			writeln(v.x," ", v.y*20);
		}

		// average weight
		uint n=0;
		double w=0;
		foreach(v; tv.range(.5)) { w+=v.y; ++n; }
		tv.v/=w/n;

		foreach(raw; data.values.sort!byAt) {
			auto post=raw.rebase(total).compress.view.normalize;
			writefln("tension %-5.2s",post.tension);
			foreach(v; post.range(.1))
				writeln(v.x," ", v.y);

			writefln("tension %-5.2s",weight(post, tv, .0).tension);
			foreach(v; weight(post, tv, .0).range(.1))
				writeln(v.x," ", v.y);

			writefln("tension %-5.2s",weight(post, tv, .3).tension);
			foreach(v; weight(post, tv, .2).range(.1))
				writeln(v.x," ", v.y);

			writefln("tension %-5.2s",weight(post, tv, .6).tension);
			foreach(v; weight(post, tv, .6).range(.1))
				writeln(v.x," ", v.y);
		}

	}

	if(STAGE == 4) {

		// average weight
		uint n=0;
		double w=0;
		foreach(v; tv.range(.5)) { w+=v.y; ++n; }
		tv.v/=w/n;

		foreach(raw; data.values.sort!byAt) {
			auto post=raw.rebase(total).compress.view.normalize;
			writeln();
			foreach(v; post.v.D2.range(.1))
				writeln(v.x," ", v.y);

			auto p0=weight(post, tv.smooth(2), .0);
			writeln();
			foreach(v; p0.v.D2.range(.1))
				writeln(v.x," ", v.y);

			auto p2=weight(post, tv.smooth(2), .2);
			writeln();
			foreach(v; p2.v.D2.range(.1))
				writeln(v.x," ", v.y);

			auto p4=weight(post, tv.smooth(2), .4);
			writeln();
			foreach(v; p4.v.D2.range(.1))
				writeln(v.x," ", v.y);

			auto p6=weight(post, tv.smooth(2), .6);
			writeln();
			foreach(v; p6.v.D2.range(.1))
				writeln(v.x," ", v.y);

		}
	}

	if(STAGE == 5) {
		writeln("total views");
		foreach(v; tv.range(.1)) {
			if(v.x > 150) break;
			writeln(v.x," ", v.y*20);
		}
		auto stv=tv.smooth(1);

		foreach(raw; data.values.sort!byAt) {
			auto post=raw.rebase(total).compress.view.normalize;

			double[] x,y;
			foreach(v; post.S(.1)) { x~=v.x; y~=-log(1.1-v.y); }
			auto lv=View(post.at, spline(x,y));

			writeln();
			foreach(v; lv.range(.1))
				writeln(v.x," ", v.y);
			writeln();
			foreach(v; lv.range(.1))
				writeln(v.x," ", v.y/(tv(v.x)+.001)/50);
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

View weight(View post, View wgt, double reg)
{
	double[] x,y;
	foreach(v; post.range(.11)) { x~=v.x; y~=v.y/(wgt(v.x)+reg); }
	return View(post.at, spline(x,y).S).normalize;
}


double tension(View post)
{
	uint n=0;
	double s=0;
	foreach(v; post.smooth(4).v.D2.range(1)) { ++n; s+=v.y*v.y; }
	return sqrt(s/n)/post(post.end);
}



