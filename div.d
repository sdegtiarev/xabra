import std.stdio;
import std.process;
import std.array;
import std.regex;
import std.exception;
import std.conv;
import std.typecons;
import std.ascii;
import std.datetime;

void main(string[] arg)
{
	string page=(arg.length > 1)? load(arg[1]) : load(1);
	auto div=dive(page, 0);
	writeln(div.opt);
	writeln(" => ",div.chld.length," subsections");
	return;
/*
	foreach(div; matchAll(page, regex(r"<div\s+(.*?)>","s"))) {
		auto cl=matchFirst(div[1], regex(`class="(.*?)"`));
		if(matchFirst(cl[1], regex(r"^post.*shortcuts_item$"))) {
			auto id=matchFirst(div[1], regex(`id="post_(.*?)"`));
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
		} else {
			//writeln("# [", cl[1] ,"]");
			//auto end=matchFirst(div.post, regex(r"<div\s+|</div>","s"));
			//writeln(end.pre);
		}
	}
*/

}



auto parse(string page)
{
	alias stat=Tuple!(uint, "post", DateTime, "at", uint, "v", uint, "m", uint, "c");
	auto div_begin=ctRegex!(r"<div\s+(.*?)>", "s");
	auto div_class=ctRegex!(`class="(.*?)"`);
	auto div_post=ctRegex!(r"^post.*shortcuts_item$");

	stat[] r;
	foreach(div; matchAll(page, div_begin)) {
		stat st;
		auto _class=matchFirst(div[1], div_class);

		if(matchFirst(_class[1], div_post)) {
			auto id=matchFirst(div[1], regex(`id="post_(.*?)"`));
			st.post=to!uint(id[1]);
		}

		if(st.post) r~=st;
	}

	return r;
}



struct Section
{
	string pre, opt, post;
	Section[] chld;
	bool div;
}


Section dive(string page, int level)
{
	enum div_start=r"<div\s+(.*?)>";
	enum div_end="</div>";
	auto divider=ctRegex!(div_start~"|"~div_end,"s");

	auto div=matchFirst(page, divider);
	if(div[0] == div_end) {
writeln("END OF LEVEL ", level);
		return Section(div.pre, "", "", [], false);
	}
writeln("AT LEVEL ", level);

	Section[] chld;
	Section nxt=dive(div.post, level+1);
	while(nxt.div)
		chld~=nxt;

	return Section(div.pre, div[1], nxt.pre, chld, true);


/*
	string pre=d1.pre, opt=d1[1];
	writeln(d1[0]);

	int level=0;
	char[] pad;
	string[] stack;
	foreach(d2; matchAll(d1.post, div_div)) {
		if(d2[0] != "</div>") {
			writeln(level,pad, d2[0]);
			++level; pad~=" ";
			stack~=d2[1];
		}	
		if(d2[0] == "</div>") {
			--level;
			if(!pad.empty) pad=pad[1..$];
			if(!stack.empty()) {
				writeln(level,pad, d2[0], stack[$-1]);
				stack=stack[0..$-1];
			} else
				writeln(level,pad, d2[0], "###");
		}
	}
	writeln;
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