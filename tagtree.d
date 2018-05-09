module tagtree;
import std.string;
import std.regex;
import std.algorithm;
import std.exception;
import std.stdio;
import loader;



TagTree!tag[] tagtree(string tag)(ref string page)
{
	TagTree!tag[] r;
	while(!page.empty()) {
		auto section=TagTree!tag(page);
		r~=section;
		if(section.empty())
			break;
	}
	return r;
}


string ident="";

struct TagTree(string tag)
{
	enum {
		  begin="<"~tag~"\\b\\s*"
		, end="</"~tag~">"
		, any=begin~"|"~end
		, options="(.*?)>"
	}

	this(ref string page) {
		auto rx=matchFirst(page, ctRegex!(any,"is"));
		if(!rx) {
			pre.swap(page);
			return;

		} else if(rx[0] == end) {
			pre=rx.pre;
			page=rx.post;
ident=chop(chop(ident));
writeln(ident,"}");

		} else {
			pre=rx.pre;
			auto rx1=matchFirst(rx.post, ctRegex!(options, "is"));

			foreach(v; split(rx1[1], ctRegex!("\"\\s+", "s"))) {
				auto kv=split(v, ctRegex!("=\\s*\""));
				if(kv.length > 1) ops[kv[0]]=(kv[1][$-1..$] == "\"")? kv[1][0..$-1] : kv[1];
			}

string name="LAMBDA";
if("class" in ops) { name=ops["class"]; ops.remove("class"); }
writeln(ident,name, "(",ops,") {");

ident~="  ";
			enforce(rx1, "unmatched >");
			page=rx1.post;
			child=tagtree!tag(page);
		}
	}

	@property bool empty() const { return child.empty; }

	private string pre;
	private TagTree!tag[] child;
	private string[string] ops;

}



void main(string[] arg)
{
	string page=(arg.length > 1)? load(arg[1]) : load(stdin);
	auto tree=tagtree!"div"(page);
	//auto tree=tagtree!"article"(page);
}