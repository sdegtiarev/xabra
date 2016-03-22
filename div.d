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

	auto s=Section(page);

/*
	auto div=dive(page, 0);
	writeln(div.opt);
	writeln(" => ",div.chld.length," subsections");
	return;
*/
}

/*

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
}
*/

enum {
	  begin=r"<div\s+"
	, end=r"</div>"
	, any=begin~"|"~end
	, options=r"(.*?)>"
}

struct Section
{
	string opt, text;
	Section[] children;
static string ident;

	enum {
		  begin=r"<div\s+"
		, end=r"</div>"
		, any=begin~"|"~end
		, options=r"(.*?)>"
	}

	this(string page) {
		auto r=matchFirst(page, begin);
		enforce(r, "no section found");
		parse(r.post);
	}

	@property string name() const {
		auto r=matchFirst(opt, ctRegex!(`class="(.*?)"`,"s"));
		return r? r[1] : "ANON";
	}
	@property string id() const {
		auto r=matchFirst(opt, ctRegex!(`id="(.*?)"`,"s"));
		return r? r[1] : "";
	}

	private string parse(string page) {
		auto r=matchFirst(page, ctRegex!(options, "s"));
		enforce(r, "section header not terminated");
		opt=r[1];
//writeln(ident,"# section [",opt,"]");
writeln(ident, this.name,"(",this.id,")");
writeln(ident, "{");
	
		page=r.post;
		do {
			r=matchFirst(page, ctRegex!(any, "s"));
			enforce(r, begin~opt~"> : section not terminated");
			text~=r.pre;
			page=r.post;
	
			if(r[0] != end) {
				ident~="  ";
				Section ch;
				page=ch.parse(page);
				children~=ch;
				ident=ident[2..$];
			}

		} while(r[0] != end);
writeln(ident, "} //",this.name);
//writeln(ident,"# finished [", opt,"]");

		return page;
	}
}

/*
string ma(string page)
{
//writeln("--------------------------------------------");
static string ident;
	Section self;
	auto r=matchFirst(page, ctRegex!(options, "s"));
	enforce(r, "section header not terminated");
	self.opt=r[1];
writeln(ident,"# section [",self.opt,"]");
	
	page=r.post;
	do {
		r=matchFirst(page, ctRegex!(any, "s"));
		enforce(r, begin~self.opt~"> : section not terminated");
		self.text~=r.pre;
		page=r.post;
		if(r[0] != end) {
			ident~="  ";
			page=ma(page);
			ident=ident[2..$];
		}

	} while(r[0] != end);
writeln(ident,"# finished [", self.opt,"]");

	return page;
}

void main(string[] arg)
{
	enforce(arg.length > 1, "no file");
	auto page=load(arg[1]);
	auto r=matchFirst(page, begin);
	enforce(r, "no section found");
	page=r.post;

	page=ma(page);
	writeln("leftover: ", page);
}

*/





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