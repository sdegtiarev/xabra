import std.stdio;
import std.process;
import std.array;
import std.regex;
import std.exception;
import std.conv;
import std.ascii;

void main(string[] arg)
{
	immutable int[string] ignore=[
		  "nav_panel" : 1
		, "menu" : 1
		, "line" : 1
		, "bmenu" : 1
		, "bmenu_inner" : 1
		, "layout_inner" : 1
		, "container" : 1
		, "hidden" : 1
		, "nav_tabs_content " : 1
		, "nav_tab hidden" : 1
		, "title" : 1
		, "inner" : 1
		, "lain_13_what_are_you_doing" : 1
		, "adb-text" : 1
		, "adb-close" : 1
		, "page_head" : 1
		, "column-wrapper" : 1
		, "content_left js-content_left" : 1
		, "tabs" : 1
		, "posts_list" : 1
		, "posts shortcuts_items" : 1
		, "hubs" : 1
		, "content html_format" : 1
		, "buttons" : 1
		, "clear" : 1
		, "infopanel_wrapper js-user_" : 1
		, "voting-wjt voting-wjt_infopanel js-voting  " : 1
		, "voting-wjt__counter js-mark" : 1
		, "post translation shortcuts_item" : 1
		, "shortcuts_item" : 1
		, "privet" : 1
		, "html_banner" : 1
		, "page-nav" : 1
		, "description" : 1
		, "sidebar_right js-sidebar_right" : 1
		, "no_please_one_one_one" : 1
		, "block hubs_categories" : 1
		, "live-broadcast live-broadcast_habrahabr daily_best_posts" : 1
		, "live-broadcast__tabs tabs" : 1
		, "tabs__content" : 1
		, "block new_companies" : 1
		, "companies_items" : 1
		, "company_item " : 1
		, "favicon" : 1
		, "all" : 1
		, "column-wrapper column-wrapper_bottom column-wrapper_bordered" : 1
		, "content_left" : 1
 		, "live-broadcast live-broadcast_feed" : 1
		, "dropdown dropdown_broadcast" : 1
		, "dropdown-container" : 1
		, "live-broadcast__content" : 1
		, "columns-group columns-group_promo" : 1
		, "columns-group__column promo-block promo-block_vacancies" : 1
		, "promo-block__content" : 1
		, "vacancy__attrs attrs" : 1
		, "promo-block__footer" : 1
		, "columns-group__column promo-block promo-block_freelansim-tasks" : 1
		, "task__attrs attrs" : 1
		, "sidebar_right" : 1
		, "float_yandex_ad" : 1
		, "footer_panel" : 1
		, "copyright" : 1
		, "about" : 1
		, "social_accounts" : 1
		, "" : 1
		, "" : 1
		, "" : 1
	];
	string page=(arg.length > 1)? load(arg[1]) : load(1);

	foreach(div; matchAll(page, regex(r"<div\s+(.*?)>","s"))) {
		auto cl=matchFirst(div[1], regex(`class="(.*?)"`));
		if(matchFirst(cl[1], regex(r"^post.*shortcuts_item$"))) {
			auto id=matchFirst(div[1], regex(`id="(.*?)"`));
			writeln(id[1]);
		} else if(cl[1] == "published") {
			auto end=matchFirst(div.post, regex(r"<div\s+|</div>","s"));
			writeln("--  published ", end.pre);
		} else if(cl[1] == "views-count_post") {
			auto end=matchFirst(div.post, regex(r"<div\s+|</div>","s"));
			writeln("--  ",end.pre, " views");
		} else if(cl[1] == "favorite-wjt favorite") {
			auto val=matchFirst(div.post, regex(`<span class=.*?>(.*?)</span>`,"s"));
			writeln("--  ",val[1], " favorites");
		} else if(cl[1] == "post-comments") {
			auto val=matchFirst(div.post, regex(`<a .*?>\s*(.*?)\s*</a>`,"s"));
			if(empty(val[1]) || !isDigit(val[1][0]))
				writeln("--  0 comments");
			else
				writeln("--  ",val[1], " comments");
		} else if(cl[1] in ignore) {
		} else {
			writeln("# [", cl[1] ,"]");
			auto end=matchFirst(div.post, regex(r"<div\s+|</div>","s"));
			writeln(end.pre);
		}
	}


/*
	page=replaceFirst(page, ctRegex!(r".*?<div","s"), "<div");
	int layer=0;
	string block;
	foreach(m; matchAll(page, div_block)) {
		assert(m.lenght=4);
		string all=m[0], begin=m[1], body=m[2], end=m[3];
		if(begin == "<div")
		{
			if(layer == 0)
			{
				if(end == "</div")
			}

		}
	}
*/
}






string load(int page)
{
	auto r=executeShell("wget -qO- https://habrahabr.ru/all/page"~to!string(page)~"/");
	enforce(!r.status, "page load error");
	return r.output;
}

string load(string file)
{
	string page;
	auto fd=File(file, "r");
	scope(exit) fd.close;
	foreach(line; fd.byLine(KeepTerminator.yes))
		page~=line;
	return page;
}