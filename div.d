import std.stdio;
import std.process;
import std.array;
import std.regex;
import std.exception;
import std.conv;
import std.typecons;
import std.ascii;
import std.datetime;
import std.string;

bool tree=false;

void main(string[] arg)
{
	foreach(id; arg[1..$]) {
		string page=load(id);

		auto s=Section(page);

		//if(tree) writeln("---------------------------------------------");
		auto data=s["inner"]["column-wrapper"]["content_left"]["company_post"]["post"]["post__header"]["hubs"];
		if(data.empty)
			data=s["inner"]["content_wrapper"]["column-wrapper"]["content_left"]["post_show"]["post"]["post__header"]["hubs"];
		//foreach(p; data.children)
		//	writeln("div: ",p.name);
		auto lines=data.text.split("\n");
		foreach(line; lines) {
			auto i1=indexOf(line,">");
			auto i2=indexOf(line,"</a>");
			if(i1 >= 0 && i2 >= 0)
				writeln(line[i1+1..i2]);
		}
	}
	

	//auto posts=s["inner"]["column-wrapper"]["content_left"]["posts_list"]["posts"];
	//if(posts.empty)
	//	writeln("no posts");
	//else
	//	foreach(p; posts.children)
	//	if(p.name == "post") {
	//		writeln(p.name,"(",p.id[5..$],")");
	//		auto pb=p["published"];
	//		writeln("    ",pb.name,": ",pb.text);
	//		auto info=p["infopanel_wrapper"];
	//		foreach(y; info.children) {
	//			if(y.name == "views-count_post")
	//				writeln("    views: ",y.text);
	//			else
	//				writeln("    ",y.name);
	//		}
	//	}
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
		if(!r) return;
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






string load(string id)
{
	auto r=executeShell("wget -qO- https://habrahabr.ru/post/"~id~"/");
	//enforce(!r.status, "page load error");
	if(r.status) return "";
	return r.output;
}

