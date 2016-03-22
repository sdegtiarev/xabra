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

	writeln("---------------------------------------------");
	writeln(s.name);
	foreach(c; s.children) {
		if(c.name == "inner") {
			writeln("  ",c.name);
			foreach(t; c.children) {
				if(t.name =="column-wrapper") {
					writeln("    ",t.name);
					foreach(u; t.children) {
						if(u.name == "content_left js-content_left") {
							writeln("      ",u.name);
							foreach(v; u.children) {
								if(v.name == "posts_list") {
									writeln("        ", v.name);
									foreach(w; v.children) {
										if(w.name == "posts shortcuts_items") {
											writeln("          ",w.name);
											foreach(x; w.children) {
												if(x.name =="post shortcuts_item") {
													writeln("            ",x.name);
													foreach(y; x.children)
														writeln("              ",y.name);
												}
											}
										}
									}
								}
							}
						}
					}
				}
			}
		}
	}
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

		return page;
	}
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