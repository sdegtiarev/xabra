module lview;
import std.datetime;
import std.container.rbtree;
import std.stdio;


struct LStat
{
	DateTime ts;
	float val;
}

alias LView=RedBlackTree!(LStat, "a.ts < b.ts");

auto get_lview() { return new LView; }

