import std.stdio;
import std.array;
import std.container;
import std.conv;
import std.datetime;
import core.stdc.time;


struct Post
{
	string name_;
	string posted_;

	struct Stat
	{
		time_t ts;
		uint view, mark, comm;
		float dv, dm, dc;
	}
	Stat first_, last_;
	RedBlackTree!(Stat, "a.ts < b.ts", false) hist_;

	this(string name, string at, Post.Stat stat)
	{
		hist_=make!(typeof(hist_))();
		this.name_=name;
		this.posted_=at;
		first_=last_=stat;
		hist_.insert(stat);
	}

	void add(Post.Stat stat)
	{
		float dt=stat.ts-last_.ts;
		stat.dv=(stat.view-last_.view)/dt;
		stat.dm=(stat.mark-last_.mark)/dt;
		stat.dc=(stat.comm-last_.comm)/dt;

		last_=stat;
		hist_.insert(stat);
	}

	string toString() {
		return name_~" "~posted_~" "~to!string(hist_.length);
	}
}



void main(string[] arg)
{
	Post[string] data;

	auto fd=File(arg[1], "r");
	foreach(line; fd.byLine) {
		auto t=line.split;
		auto ts=to!time_t(t[0]);
		string name=t[1].idup;
		string at=t[2].idup;
		auto v=to!uint(t[3]);
		auto c=to!uint(t[4]);
		auto m=to!uint(t[5]);

		auto post=Post(name, at, Post.Stat(ts, v,m,c));
		if(name in data)
			data[name].add(Post.Stat(ts, v,m,c));
		else
			data[name]=Post(name, at, Post.Stat(ts, v,m,c));
	}

	foreach(post; data.byValue)
		writeln(post);
}