module tagstat;
import std.string;
import std.regex;
import std.stdio;
import loader;




void main(string[] arg)
{
	string page=(arg.length > 1)? load(arg[1]) : load(stdin);

	int[string] stat;
	auto rx=matchAll(page, "<(\\w+)\\s+");
	foreach(s; rx)
		stat[s[1]]++;

	foreach(s; stat.byKey)
		writeln(stat[s]," ", s);
}

