import std.string;
import std.regex;
import std.range;
import std.algorithm;
import std.exception;
import std.datetime;
import std.conv;
import std.stdio;
import loader;
import tagged;

void main(string[] arg)
{
	auto t0=now();
	string page=(arg.length > 1)? load(arg[1]) : load(stdin);
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
	foreach(it; post.list!"class"("post post_teaser shortcuts_item")) {
		//writeln("post ", it.opt["id"][5..$]);
		auto dt=section!"span"(it["post__header"].text);
		if(strip(dt.at("post__time_published").text).empty)
			continue;
		//writeln(strip(dt["post__time_published"].text));

		auto info=it["post__footer"]["infopanel_wrapper js-user_"];
		//writeln("\tviews ", info["views-count_post"].text);

		auto st=section!"span"(info["favorite-wjt favorite"].text);
		//writeln("\tstarred ", st["favorite-wjt__counter js-favs_count"].text);

		auto cm=section!"a"(info["post-comments"].text);
		auto ncm=cm.at("post-comments__link post-comments__link_all").text;
		if(ncm.empty) ncm="0";
		//writeln("\tcomments ", cm.at("post-comments__link post-comments__link_all").text);

		writefln("%-8s %s  %-12s    %-6s    %-4s %4s"
			, it.opt["id"][5..$]
			, at(strip(dt.at("post__time_published").text), t0)
			//, t0
			, (t0-at(strip(dt.at("post__time_published").text), t0)).total!"seconds"
			, views(info["views-count_post"].text)
			, st["favorite-wjt__counter js-favs_count"].text
			, ncm
		);

	}

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


