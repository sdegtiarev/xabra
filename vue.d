import std.stdio;
import std.array;
import std.container;
import std.conv;
import std.range;
import std.algorithm;
import std.datetime;
import std.traits;
import std.getopt;

struct Post
{
	string name_;
	DateTime posted_;
	static immutable auto epoch=DateTime(1970, 1, 1)+dur!"hours"(3);

	struct Stat
	{
		DateTime ts;
		uint view, mark, comm;
		float dv, dm, dc;
	}
	Stat first_, last_;
	RedBlackTree!(Stat, "a.ts < b.ts", false) hist_;

	//@property auto at() const { return DateTime.fromISOExtString(posted_); }
	//@property auto begin() const { return DateTime.fromISOExtString(first_.ts); }
	//@property auto end() const { return DateTime.fromISOExtString(last_.ts); }
	@property auto at() const { return posted_; }
	@property auto begin() const { return first_.ts; }
	@property auto end() const { return last_.ts; }

	this(string name, string at, Post.Stat stat)
	{
		hist_=make!(typeof(hist_))();
		this.name_=name;
		this.posted_=DateTime.fromISOExtString(at);
		first_=last_=stat;
	}

	void add(Post.Stat stat)
	{
		//float dt=(stat.ts-end).to!TickDuration.seconds;
		float dt=(stat.ts-end).total!"seconds";
		stat.dv=(stat.view-last_.view)/dt;
		stat.dm=(stat.mark-last_.mark)/dt;
		stat.dc=(stat.comm-last_.comm)/dt;

		last_=stat;
		hist_.insert(stat);
	}

	string toString() {
		return name_~" "~to!string(posted_)~" "~to!string(hist_.length);
	}
}



void main(string[] arg)
{
	Post[string] data;
	int id=0;
	bool list=0, total=0, favorites=0;
	getopt(arg,
		  "p|post", &id
		, "l|list", &list
		, "t|total", &total
		, "m|marks", &favorites
	);

	auto fd=File(arg[1], "r");
	foreach(line; fd.byLine) {
		auto t=line.split;
		string ts=t[0].idup;
		string name=t[1].idup;
		string at=t[2].idup;
		auto v=to!uint(t[3]);
		auto c=to!uint(t[4]);
		auto m=to!uint(t[5]);

		auto post=Post(name, at, Post.Stat(DateTime.fromISOExtString(ts), v,m,c));
		if(name in data)
			data[name].add(Post.Stat(DateTime.fromISOExtString(ts), v,m,c));
		else
			data[name]=Post(name, at, Post.Stat(DateTime.fromISOExtString(ts), v,m,c));
	}

	// list posts
	if(list) foreach(post; data.byValue)
		writeln(post.hist_.length," ",post.name_," ",post.at);

	//// list post start/end times
	//foreach(post; data.byValue)
	//	writeln(post.name_,": ", post.at, " -- ", post.begin, " -- ", post.end);

	if(id) {
		auto post=data[to!string(id)];
		writeln("post ",id);
		foreach(stat; post.hist_) {
			ulong t=(stat.ts-post.at).total!"seconds";
			writeln(t," ",stat.dv);
		}
	}

	if(total) {
		float[DateTime] sum;
		foreach(post; data) {
			foreach(stat; post.hist_) {
				if(stat.ts in sum)
					sum[stat.ts]+=stat.dv;
				else
					sum[stat.ts]=stat.dv;
			}
		}
		DateTime[] ts=sum.keys.sort;
		foreach(t; ts)
			writeln((t-ts[0]).total!"seconds"," ",sum[t]);
	}
	if(favorites) {
		float[DateTime] sum;
		foreach(post; data) {
			foreach(stat; post.hist_) {
				if(stat.ts in sum)
					sum[stat.ts]+=stat.dm;
				else
					sum[stat.ts]=stat.dm;
			}
		}
		DateTime[] ts=sum.keys.sort;
		foreach(t; ts)
			writeln((t-ts[0]).total!"seconds"," ",sum[t]);
	}
}

auto smoothAvg(R)(R r)
if(isInputRange!(Unqual!R))
{
	return SmoothAvg!R(r);
}

struct SmoothAvg(R)
{
	alias T=ElementType!(Unqual!R);
	this(R r) {
		data_=r;
		i_=0;
	}

	@property bool empty() const {
		return i_ >= data_.length;
	}
	T front() {
		if(i_ < 2 || i_ > data_.length-3) {
			return data_[i_];
		}
		T s=0;
		foreach(v; data_[i_-2..i_+3]) s+=v;
		return s/5;
	}
	void popFront() {
		++i_;
	}

	R data_;
	size_t i_;
}



