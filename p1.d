import post;
import local.getopt;
import local.spline;
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
	
/*
	DateTime start=data.values.front.at, end=data.values.front.stat.back.ts;
	foreach(raw; data) {
		start=min(start,raw.at);
		end=max(end,raw.stat.back.ts);
	}


	foreach(raw; data) {
		if(raw.start > 30) continue;
		if(raw.end < 1440) continue;
		auto post=raw.compress;
		post.at=start;
		auto view=post.view;

		writeln("post ", post.id," ", view.at);
		for(auto t=view.start; t <= view.end; t+=.1)
			writeln(t," ",view(t));
	}
*/

	foreach(raw; data)
	{
		if(raw.start > 30) continue;
		if(raw.end < 1440) continue;
		auto post=raw.compress;
		double scale=post.stat.back.view;

		double[] x, y;
		foreach(stat; post.range) {
			x~=stat[0]/60.;
			y~=stat[1]/scale;
		}
		auto view=spline(x,y);
		writeln;
		for(auto t=view.min; t <= view.max; t+=.1)
			writeln(t," ",view(t));
			//writeln(t," ",view.der1(t));

	}

}