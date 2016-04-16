import post;
import local.getopt;
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


	foreach(raw; data)
	{
		if(raw.start > 30) continue;
		if(raw.end < 1440) continue;
		auto post=raw.compress;
		double scale=post.stat.back.view;
		writeln("post ", post.id, " ", post.at);
		foreach(st; post.rebase(total).range)
			writeln(st[0]/60.," ",st[1]/scale);
	}

}