module lview;
import std.datetime;
import std.container.rbtree;
import std.range;
import std.stdio;


struct LStat
{
	DateTime ts;
	float val;
}

alias LView=RedBlackTree!(LStat, "a.ts < b.ts");

LView lsmooth(uint N)(LView x)
{
	auto s=x[].array;
	auto r=new LView;
	r.insert(s[0]);
	r.insert(LStat(s[1].ts, (s[0].val+s[1].val+s[2].val)/3));
	foreach(i; 2..s.length-2)
		r.insert(LStat(s[i].ts, (s[i-2].val+s[i-1].val+s[i].val+s[i+1].val+s[i+2].val)/5));
	r.insert(LStat(s[s.length-2].ts, (s[s.length-3].val+s[s.length-2].val+s[s.length-1].val)/3));
	r.insert(s[s.length-1]);
	static if(N == 1)
		return r;
	else
		return lsmooth!(N-1)(r);
}
