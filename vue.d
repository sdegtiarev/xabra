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

	@property auto id() const { return name_; }
	@property auto at() const { return posted_; }
	@property auto begin() const { return first_.ts; }
	@property auto end() const { return last_.ts; }
	@property auto max() const { return last_.view; }

	this(T)(T name, string at, Post.Stat stat)
	{
		hist_=make!(typeof(hist_))();
		this.name_=to!string(name);
		this.posted_=DateTime.fromISOExtString(at);
		first_=last_=stat;
	}

	void add(Post.Stat stat)
	{
		float dt=(stat.ts-end).total!"seconds";
		if(stat.view < last_.view) stat.view=last_.view;
		if(stat.mark < last_.mark) stat.mark=last_.mark;
		if(stat.comm < last_.comm) stat.comm=last_.comm;
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
	Post[int] data;
	int id=0, mid=0, cid=0, cm=0, raw;
	bool list=0, gap=0, total=0, log_scale;
	getopt(arg,
		  config.caseSensitive, config.bundling
		, "p|post", &id
		, "L|log", &log_scale
		, "l|list", &list
		, "g|gap", &gap
		, "t|total", &total
		, "m|mark", &mid
		, "c|comment", &cid
		//, "r", &cm
		, "r|raw", &raw
	);

	auto fd=File(arg[1], "r");
	foreach(line; fd.byLine) {
		auto t=line.split;
		string ts=t[0].idup;
		int name=to!int(t[1]);
		string at=t[2].idup;
		auto v=to!uint(t[3]);
		auto m=to!uint(t[4]);
		auto c=to!uint(t[5]);

		auto post=Post(name, at, Post.Stat(DateTime.fromISOExtString(ts), v,m,c));
		if(name in data)
			data[name].add(Post.Stat(DateTime.fromISOExtString(ts), v,m,c));
		else
			data[name]=Post(name, at, Post.Stat(DateTime.fromISOExtString(ts), v,m,c));
	}

	// list posts
	if(list) foreach(post; data.byValue)
		writeln(post.hist_.length," ",post.max," ",(post.begin-post.at).total!"minutes"," ",post.name_," ",post.at);

	if(id) {
		float[DateTime] sum=average(total_views(data));
		auto post=data[id];
		auto t0=post.at;
		float[DateTime] dv;
		foreach(stat; post.hist_)
			dv[stat.ts]=stat.dv;
		auto sdv=average(dv);

		float mx=0;
		foreach(t; sdv.keys.sort) {
			sdv[t]/=sum[t];
			if(sdv[t] > mx)
				mx=sdv[t];
		}

		writeln("post ",post);
		foreach(t; sdv.keys.sort)
		if(sum[t] > 0) {
			auto ts=(t-t0).total!"seconds"/3600.;
			if(log_scale) {
				auto v=(sdv[t] > 0)? log(sdv[t]) : -10;
				if(v > -6)
					writeln(ts," ",v);
			}
			else {
				writeln(ts," ",sdv[t]/mx);
			}
		}
	}
	if(raw) {
		auto post=data[raw];
		auto t0=post.at;
		float[DateTime] dv;
		foreach(stat; post.hist_)
			dv[stat.ts]=stat.dv;
		auto sdv=average(dv);

		float mx=0;
		foreach(t; sdv.keys.sort) {
			if(sdv[t] > mx)
				mx=sdv[t];
		}

		writeln("post ",post);
		foreach(t; sdv.keys.sort) {
			auto ts=(t-t0).total!"seconds"/3600.;
			writeln(ts," ",sdv[t]/mx);
		}
	}



	if(mid) {
		float[DateTime] sum=average(total_views(data));
		auto post=data[mid];
		auto t0=post.at;
		float[DateTime] dm;
		foreach(stat; post.hist_)
			dm[stat.ts]=stat.dm;
		auto sdm=average(dm);

		writeln("post ",post);
		foreach(t; dm.keys.sort)
		if(sum[t] > 0) {
			auto ts=(t-t0).total!"seconds"/3600.;
			if(log_scale && sdm[t] > 0)
				writeln(ts," ",log(sdm[t]/sum[t]));
			else
				writeln(ts," ",sdm[t]/sum[t]);
		}
	}


	if(cid) {
		float[DateTime] sum=average(total_views(data));
		auto post=data[cid];
		auto t0=post.at;
		float[DateTime] dc;
		foreach(stat; post.hist_)
			dc[stat.ts]=stat.dc;
		auto sdc=average(dc);

		writeln("post ",post);
		foreach(t; dc.keys.sort)
		if(sum[t] > 0) {
			auto ts=(t-t0).total!"seconds"/3600.;
			if(log_scale && sdc[t] > 0)
				writeln(ts," ",log(sdc[t]/sum[t]));
			else
				writeln(ts," ",sdc[t]/sum[t]);
		}
	}

	if(cm) {
		auto post=data[cm];
		writeln("post ",post);
		foreach(stat; post.hist_) {
			if(stat.view == 0 || stat.mark == 0 || stat.comm == 0)
				continue;
			float view=stat.view;
			if(log_scale)
				writeln(log(stat.mark/view)," ",log(stat.comm/view));
			else
				writeln(stat.mark/view," ",stat.comm/view);
		}

	}


	if(total) {
		float[DateTime] sum=average(total_views(data));
		DateTime t0=sum.keys.sort[0].date;
		foreach(ts; sum.keys.sort)
			writeln((ts-t0).total!"seconds"/3600.," ",sum[ts]);
	}


	if(gap) {
		foreach(post; data) {
		//	DateTime last=post.at;
		//	int cnt=0;
		//	foreach(stat; post.hist_) {
		//		auto t=(stat.ts-last);
		//		if(t > 30.dur!"minutes") {
		//			//writeln("    ",stat.ts,": ", t.total!"minutes"/60.);
		//			++cnt;
		//		}
		//		last=stat.ts;
		//	}
		//	if(!cnt) writeln(post.id);
		//}
			if((post.begin-post.at) < dur!"minutes"(30)
				&& (post.end-post.at) > dur!"hours"(12))
				writeln(post.id);
		}
	}
}


float[DateTime] total_views(Post[int] data)
{
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



