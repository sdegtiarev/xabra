import std.stdio;
import std.string;
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
	string page=(arg.length > 1)? load(arg[1]) : load(stdin);

	while(!page.empty) {
		auto s=Section(page);
		page=s.left;
	}

}




struct Section
{
	string opt, text;
	Section[] children;
static string ident;

	enum {
		  begin="<div\\s+"
		, end="</div>"
		, any=begin~"|"~end
		, options="(.*?)>"
	}

	this(string page) {
		auto r=matchFirst(page, begin);
		enforce(r, "no section found");
		parse(r.post);
	}

	Section opIndex(string target) {
		if(this.empty)
			return this;
		foreach(c; children) {
			if(c.name == target)
				return c;
		}
		return Section();
	}

	@property bool empty() const {
		return opt.empty && text.empty && children.empty;
	}

	@property string full_name() const {
		auto r=matchFirst(opt, ctRegex!(`class="(.*?)"`,"s"));
		return r? r[1] : "ANON";
	}
	@property string name() const {
		auto r=matchFirst(opt, ctRegex!(`class="(.*?)["\s]`,"s"));
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
if(tree) writeln(ident, this.name,"(",this.id,")");
if(tree) writeln(ident, "{");
	
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
if(tree) writeln(ident, "} //",this.name);

		return page;
	}
}






string load(int page)
{
	auto r=executeShell("wget -qO- https://habrahabr.ru/all/"~to!string(page)~"/");
	enforce(!r.status, "page load error");
	return r.output;
}

string load(string file)
{
	string page;
	auto fd=File(file, "r");
	scope(exit) fd.close;
	return load(fd);
}


string load(File fd)
{
	foreach(line; fd.byLine(KeepTerminator.yes))
		page~=line;
	return page;
}
