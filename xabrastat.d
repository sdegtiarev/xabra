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
		Thread.sleep(dur!"minutes"(repeat));
	} while(repeat);
}




bool process(int n, int days)
{
	string page=page(n);
	auto t0=now();
	auto top=section!"div"(page);


	auto post=top
		["layout"]
		["layout__row layout__row_body"]
		["layout__cell layout__cell_body"]
		["column-wrapper column-wrapper_lists js-sticky-wrapper"]
		["content_left js-content_left"]
		["posts_list"]
		["posts shortcuts_items"]
		;

	int pgcnt=0;
	foreach(it; post.list!"class"("post post_teaser shortcuts_item")) {
		auto dt=section!"span"(it["post__header"].text);
		if(strip(dt.at("post__time_published").text).empty)
			continue;

		auto ts=(t0-at(strip(dt.at("post__time_published").text), t0)).total!"seconds";
		if(ts > days*24*60*60)
			continue;
		++pgcnt;


		auto info=it["post__footer"]["infopanel_wrapper js-user_"];
		auto st=section!"span"(info["favorite-wjt favorite"].text);

		auto cm=section!"a"(info["post-comments"].text);
		auto ncm=cm.at("post-comments__link post-comments__link_all").text;
		if(ncm.empty) ncm="0";

		auto vts=info["voting-wjt voting-wjt_infopanel js-voting  "]["voting-wjt__counter voting-wjt__counter_positive  js-mark"];
		auto vt=section!"span"(vts.text)["voting-wjt__counter-score js-score"].opt["title"].split(";");


		writefln("%-8s %s  %-12s    %-6s    %-4s %4s    : %s"
			, it.opt["id"][5..$]
			, at(strip(dt.at("post__time_published").text), t0)
			, ts
			, views(info["views-count_post"].text)
			, st["favorite-wjt__counter js-favs_count"].text
			, ncm
			, vt
		);
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


