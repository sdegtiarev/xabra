import std.stdio;
import std.array;
import std.container;
import std.conv;
import std.range;
import std.algorithm;
import std.datetime;
import std.traits;
import std.typecons;
import std.getopt;
import core.stdc.math;

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
	bool list=0, total=0, marks=0;
	getopt(arg,
		  "p|post", &id
		, "l|list", &list
		, "t|total", &total
		, "m|marks", &marks
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

	if(id) {
//<<<<<<< HEAD
		//float[ulong] sum=average(total_views(data));
		float[DateTime] sum=average(total_views(data));
		auto post=data[to!string(id)];
		writeln(post);
		auto t0=post.at;
		//float[ulong] dv;
		float[DateTime] dv;
		foreach(stat; post.hist_)
			dv[stat.ts]=stat.dv;
		auto sdv=average(dv);

		foreach(t; dv.keys.sort) {
			if(sdv[t] > 0) writeln(t-t0," ",log(sdv[t]/sum[t]));
//=======
//		auto post=data[to!string(id)];
//		writeln("post ",id);
//		foreach(stat; post.hist_) {
//			ulong t=(stat.ts-post.at).total!"seconds";
//			writeln(t," ",stat.dv);
//>>>>>>> wget
		}
	}

	if(total) {
//<<<<<<< HEAD
		//float[ulong] sum=average(total_views(data));
		float[DateTime] sum=average(total_views(data));
		foreach(ts; sum.keys.sort)
			writeln(ts-sum[0]," ",sum[ts]);
	}


	if(marks) {
//		float[ulong] sum;
//=======
		float[DateTime] sum;
//>>>>>>> wget
		foreach(post; data) {
			foreach(stat; post.hist_) {
				if(stat.ts in sum)
					sum[stat.ts]+=stat.dm;
				else
					sum[stat.ts]=stat.dm;
			}
		}
//<<<<<<< HEAD
		auto rng=sum.keys.sort;
		writeln(typeid(rng));
		foreach(ts; sum.keys.sort)
			writeln(ts," ",sum[ts]*200);
	}
}


//float[ulong] total_views(Post[string] data)
float[DateTime] total_views(Post[string] data)
{
	//float[ulong] sum;
	float[DateTime] sum;
	foreach(post; data) {
		foreach(stat; post.hist_) {
			if(stat.ts in sum)
				sum[stat.ts]+=stat.dv;
			else
				sum[stat.ts]=stat.dv;
		}
	}
	return sum;
}



auto average(R)(R data) {
	auto r=data;
	auto ts=data.keys.sort;
	while(ts.length > 5) {
		auto x=ts.take(5);
		auto y=x.map!(a => data[a]).sum/5;
		r[x[2]]=y;
		ts.popFront();
//=======
//		DateTime[] ts=sum.keys.sort;
//		foreach(t; ts)
//			writeln((t-ts[0]).total!"seconds"," ",sum[t]);
//	}
//	if(favorites) {
//		float[DateTime] sum;
//		foreach(post; data) {
//			foreach(stat; post.hist_) {
//				if(stat.ts in sum)
//					sum[stat.ts]+=stat.dm;
//				else
//					sum[stat.ts]=stat.dm;
//			}
//		}
//		DateTime[] ts=sum.keys.sort;
//		foreach(t; ts)
//			writeln((t-ts[0]).total!"seconds"," ",sum[t]);
//>>>>>>> wget
	}
	return r;
}


auto smoothAvg(R)(R r)
{
	return SmoothAvg!R(r);
}

struct SmoothAvg(R)
{
	alias T=ElementType!(Unqual!R);
	this(R r) {
		data_=r;
		stream_=data_.keys.sort;
	}

	@property bool empty() const {
		return stream_.empty;
	}
	auto front() {
		auto sample=stream_.map!(a => data_[a]).take(5);
		auto l=sample.length;
		return tuple(stream_.front, sample.sum/l);
	}
	void popFront() { stream_.popFront(); }

	R data_;
	typeof(data_.keys.sort) stream_;
}

auto medianAvg(R)(R r)
{
	return MedianAvg!R(r);
}
struct MedianAvg(R)
{
	alias T=ElementType!(Unqual!R);
	this(R r) {
		data_=r;
		stream_=data_.keys.sort;
	}

	@property bool empty() const {
		return stream_.empty;
	}
	auto front() {
		auto sample=stream_.map!(a => data_[a]).take(5);//.sort;
		auto ss=sample[0..$];
writeln("# ",typeid(ss),": ",ss.length, " => ", typeid(T));
		return tuple(stream_.front, sample[sample.length/2]);
	}
	void popFront() { stream_.popFront(); }

	R data_;
	typeof(data_.keys.sort) stream_;
}



