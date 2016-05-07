module view;
import std.datetime;
import std.container.rbtree;
import std.typecons;
import std.algorithm;
import std.range;
import std.stdio;


struct Stat
{
	DateTime ts;
	float val;
}

alias View=RedBlackTree!(Stat, "a.ts < b.ts");

View add(View view, DateTime ts, float val)
{
	view.insert(Stat(ts,val));
	return view;
}

View smooth(View view,uint N)
{
	if(N == 0) return view;
	auto s=view[].array;
	auto d=view[].array;
	d[0]=s[0];
	d[1]=Stat(s[1].ts, (s[0].val+s[1].val+s[2].val)/3);
	foreach(i; 2..s.length-2)
		d[i]=Stat(s[i].ts, (s[i-2].val+s[i-1].val+s[i].val+s[i+1].val+s[i+2].val)/5);
	d[$-2]=Stat(s[$-2].ts, (s[$-3].val+s[$-2].val+s[$-1].val)/3);
	d[$-1]=s[$-1];
	return new View(d).smooth(N-1);
}

DateTime start(View view) { return view.front.ts; }
DateTime end(View view) { return view.back.ts; }


View normalize(View view)
{
	auto sum=view[].map!(a => a.val).sum/view.length;
	View r=new View;
	foreach(v; view) r.add(v.ts, v.val/sum);
	return r;
}

View weight(View view, View base)
{
	View r=new View;
	float[DateTime] w;
	foreach(v; base) w[v.ts]=v.val;
	foreach(v; view) r.add(v.ts, v.val/w[v.ts]);
	return r;
}


auto range(View view)
{
	return ViewRange(view.front.ts, view[]);
}

auto range(View view, DateTime at)
{
	return ViewRange(at, view[]);
}

struct ViewRange
{
	DateTime t0;
	typeof(View.opSlice()) range;

	@property bool empty() const { return range.empty(); }
	void popFront() { range.popFront(); }
	auto front() {
		float t=(range.front.ts-t0).total!"seconds"/3600.;
		float v=range.front.val;
		return tuple!("time","value","ts")(t,v,range.front.ts);
	}
}

