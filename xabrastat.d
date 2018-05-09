import std.string;
import std.regex;
import std.range;
import std.algorithm;
import std.exception;
import std.datetime;
import std.conv;
import std.process;
import core.thread;
import std.stdio;
import loader;
import tagged;
import local.getopt;

void main(string[] arg)
{

	int PAGES=25, DAYS=2;
	int repeat=0;
	bool help;
	Option[] opt;
	getopt(opt, arg //,noThrow.yes
		, "-p|--pages", "max. number of pages to explore", &PAGES
		, "-d|--days", "max. number of days to explore", &DAYS
		, "-f|--for", "repeat every X minutes", &repeat

		, "-h|-?|--help", "print this help", &help, true
	);
	if(help) {
		writeln(arg[0], " gather habrahabr statistics");
		writeln("Syntax: ", arg[0], " [OPTIONS | -h]");
		writeln("Options:\n",optionHelp(sort!("a.group < b.group || a.group == b.group && a.tag < b.tag")(opt)));
		return;
	}

	do {
		for(int i=1; i <= PAGES && process(i, DAYS); ++i) {}
		stdout.flush;
		Thread.sleep(dur!"minutes"(repeat));
	} while(repeat);
}




bool process(int n, int days)
{
	int pgcnt=0;
	string page=page(n);
	auto t0=now();
	auto top=section!"article"(page);

	foreach(x; top.list!"class"("post post_preview")) {
		//writeln(section!"a"(x.text)["post__title_link"].text);
		auto id=section!"div"(x.text)[regex("voting-wjt.*")].opt["data-id"];

		auto ar=section!"span"(x.text);
		auto t1=at(ar["post__time"].text, t0);

		auto vt=votes(ar[regex("voting-wjt__counter.*")].opt["title"]);

		auto vs=views(ar["post-stats__views-count"].text);
		auto cm=ar["post-stats__comments-count"].text; if(cm.empty) cm="0";
		auto bm=ar["btn_inner"][regex("bookmark__counter.*")].text;
		
		auto ts=(t0-t1).total!"seconds";
		if(ts > days*24*60*60)
			continue;
		++pgcnt;

		writef("%-6s %-20s %-20s    %-6s %-4s %-4s %-4s %-4s"
			, id, t0.toISOExtString, t1.toISOExtString
			, vs, vt[0], vt[1], cm, bm
		);

		write("#", ar["post__type-label"].text, " ");
		write(section!"a"(x.text).list!"class"(regex("inline-list__item-link hub-link *")).map!(a => a.text));
		writeln;
	}
	return pgcnt > 0;
}



string page(int n)
{
	auto url="https://habrahabr.ru/all/page"~to!string(n);
	auto r=execute(["wget", "-qO-", url]);
	enforce(r.status == 0, "failed get url: "~url);
	return r.output;
}


int views(string s)
{
	if(s[$-1..$] == "k") {
		auto n=indexOf(s, ',');
		if(n > 0)
			return cast(int)(1000*to!float(s[0..n]~"."~s[n+1..$-1]));
		else
			return 1000*to!int(s[0..$-1]);
	} else {
		return to!int(s);
	}
}

auto votes(string s)
{
	auto r=matchFirst(s, ctRegex!"&uarr;([0-9]+).*&darr;([0-9]+)");
	return [r[1],r[2]];
}

DateTime now(string zone="Europe/Moscow")
{
	auto tz=PosixTimeZone.getTimeZone(zone);
	auto t=Clock.currTime(tz);
	return DateTime(t.year, t.month, t.day, t.hour, t.minute, t.second);
}


//immutable ubyte[string] Months=[
//	  "января" : 1
//	, "февраля" : 2
//	, "марта" : 3
//	, "апреля" : 4
//	, "мая" : 5
//	//, "" : 
//	//, "" : 
//	//, "" : 
//	//, "" : 
//	//, "" : 
//	//, "" : 
//	//, "" : 
//	//, "" : 
//	//, "" : 
//	//, "" : 
//	//, "" : 
//	//, "" : 
//];

DateTime at(string s, DateTime now)
{

	auto r=matchFirst(s,ctRegex!"сегодня в (\\d+):(\\d+)");
	if(r)
		return DateTime(now.year, now.month, now.day, to!int(r[1]), to!int(r[2]));

	r=matchFirst(s,ctRegex!"вчера в (\\d+):(\\d+)");
	if(r)
		return DateTime(now.year, now.month, now.day, to!int(r[1]), to!int(r[2]))-days(1);

	r=matchFirst(s,ctRegex!"(\\d+) января в (\\d+):(\\d+)");
	if(r)
		return DateTime(now.year, 1, to!int(r[1]), to!int(r[2]), to!int(r[3]));

	r=matchFirst(s,ctRegex!"(\\d+) февраля в (\\d+):(\\d+)");
	if(r)
		return DateTime(now.year, 2, to!int(r[1]), to!int(r[2]), to!int(r[3]));

	r=matchFirst(s,ctRegex!"(\\d+) марта в (\\d+):(\\d+)");
	if(r)
		return DateTime(now.year, 3, to!int(r[1]), to!int(r[2]), to!int(r[3]));

	r=matchFirst(s,ctRegex!"(\\d+) апреля в (\\d+):(\\d+)");
	if(r)
		return DateTime(now.year, 4, to!int(r[1]), to!int(r[2]), to!int(r[3]));

	r=matchFirst(s,ctRegex!"(\\d+) мая в (\\d+):(\\d+)");
	if(r)
		return DateTime(now.year, 5, to!int(r[1]), to!int(r[2]), to!int(r[3]));

	r=matchFirst(s,ctRegex!"(\\d+) июня в (\\d+):(\\d+)");
	if(r)
		return DateTime(now.year, 6, to!int(r[1]), to!int(r[2]), to!int(r[3]));

	r=matchFirst(s,ctRegex!"(\\d+) июля в (\\d+):(\\d+)");
	if(r)
		return DateTime(now.year, 7, to!int(r[1]), to!int(r[2]), to!int(r[3]));

	r=matchFirst(s,ctRegex!"(\\d+) августа в (\\d+):(\\d+)");
	if(r)
		return DateTime(now.year, 8, to!int(r[1]), to!int(r[2]), to!int(r[3]));

	r=matchFirst(s,ctRegex!"(\\d+) сентября в (\\d+):(\\d+)");
	if(r)
		return DateTime(now.year, 9, to!int(r[1]), to!int(r[2]), to!int(r[3]));

	r=matchFirst(s,ctRegex!"(\\d+) октября в (\\d+):(\\d+)");
	if(r)
		return DateTime(now.year, 10, to!int(r[1]), to!int(r[2]), to!int(r[3]));

	r=matchFirst(s,ctRegex!"(\\d+) ноября в (\\d+):(\\d+)");
	if(r)
		return DateTime(now.year, 11, to!int(r[1]), to!int(r[2]), to!int(r[3]));

	r=matchFirst(s,ctRegex!"(\\d+) декабря в (\\d+):(\\d+)");
	if(r)
		return DateTime(now.year, 12, to!int(r[1]), to!int(r[2]), to!int(r[3]));

	enforce(false, s~": unhandled date");
	return now;
}


