import std.stdio;
import std.datetime;
import std.conv;


static immutable auto epoch=DateTime(1970, 1, 1)-dur!"hours"(4);

void main(string[] arg)
{
	foreach(t; arg[1..$]) {
		auto dt=to!ulong(t);
		writeln(epoch+dur!"seconds"(dt));
	}

/*
	DateTime last;
	foreach(date; arg[1..$]) {
		auto now=DateTime.fromISOExtString(date);
		auto dt=now-last;
		writeln(last, "  --  ", now,": ", dt.total!"seconds");
		last=now;
	}
*/
}
