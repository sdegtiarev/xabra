import std.stdio;
import std.datetime;



void main()
{
	auto time=cast(DateTime) Clock.currTime;
	writeln(time.toISOExtString);
	auto mime=cast(DateTime) SysTime(Clock.currStdTime, TimeZone.getTimeZone("Europe/Moscow"));
	writeln(mime.toISOExtString);
}