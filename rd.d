import std.stdio;
import std.algorithm;
import std.typecons;



void main()
{
	int[string] m=[
		  "A" : 41
		, "B" : 42
		, "C" : 43
		, "D" : 44
		, "E" : 45
		, "F" : 46
		, "G" : 47
	];

	foreach(v; m.keys.sort.map!(a => tuple!("ts", "views")(a, m[a])))
		writeln(v.ts," ",v.views);
}