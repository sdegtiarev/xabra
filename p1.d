import post;
import local.getopt;
import std.array;
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


	foreach(raw; data)
	{
		if(raw.start > 30) continue;
stderr.writeln(raw.end, " minutes");
		if(raw.end < 1440) continue;
		auto post=raw.compress;
		writeln("post ", post.id, " ", post.at.timeOfDay);
		foreach(st; post.range)
			writeln(st[0]/60.," ",st[1]);
		//writeln("raw data");
		//foreach(st; raw.range)
		//	writeln(st[0]/60.," ",st[1]);
	}

}