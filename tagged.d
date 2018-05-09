module tagged;
import std.string;
import std.regex;
import std.range;
import std.algorithm;
import std.exception;
import std.stdio;


Section!TAG section(string TAG)(string page)
{
	Section!TAG r;
	r.children=section_list!TAG(page);
	return r;
}

private Section!TAG[] section_list(string TAG)(ref string page)
{
	Section!TAG[] lst;
	while(1) {
		Section!TAG s;
		auto r=matchFirst(page, ctRegex!(Section!TAG.any, "is"));
		if(!r) {
			swap(s.prefix, page);
			lst~=s;
			break;
		} else if(r[0] == Section!TAG.end) {
			s.prefix=r.pre;
			page=r.post;
			lst~=s;
			break;
		} else /* if(r[0] == Section!TAG.begin) */{
			s.prefix=r.pre;

			auto op=matchFirst(r.post, ctRegex!(Section!TAG.options, "s"));
			enforce(op, "section header not terminated");
			s.opt=options(op[1]);

			page=op.post;
			s.children=section_list!TAG(page);
			lst~=s;

		}
	}

	return lst;
}



private string[string] options(string ops)
{
	string[string] op;
	foreach(r; matchAll(ops, ctRegex!("\\s*(.*?)=\"(.*?)\"")))
		op[r[1]]=r[2];
	return op;
}

struct Section(string TAG)
{
	string prefix;
	string[string] opt;
	Section[] children;

	enum {
		  begin="<"~TAG~"\\s*"
		, end="</"~TAG~">"
		, any=begin~"|"~end
		, options="(.*?)>"
	}


//	auto opIndex(string key)
//	{
//		auto x=children.filter!(a => "class" in a.opt && a.opt["class"] == key);
//if(x.empty) {
//	foreach(a; children)
//		if("class" in a.opt) writeln("\tcmp \"", a.opt["class"], "\" with \"", key, "\"");
//}
//		enforce(!x.empty, "no class \""~key~"\" found in section");
//		return x.front;
//	}

	auto opIndex(string key)
	{
		auto x=children.filter!(a => "class" in a.opt && a.opt["class"] == key);
		if(x.empty) return Section!TAG();
		return x.front;
	}

	auto opIndex(Regex!char key)
	{
		auto x=children.filter!(a => "class" in a.opt && matchAll(a.opt["class"], key));
		if(x.empty) return Section!TAG();
		return x.front;
	}

	auto list(string key)(string val)
	{
		return children.filter!(a => key in a.opt && a.opt[key] == val);
	}
	auto list(string key)(Regex!char val)
	{
		return children.filter!(a => key in a.opt && matchAll(a.opt[key], val));
	}

	@property string name() const { return ("class" in opt)? opt["class"] : "LAMBDA"; }
	@property string text() const { string s; foreach(ch; children) s~=ch.prefix; return s; }

	auto branches() const { return children.map!(a => a.name); }



	void print(string ident ="")
	{
		if(children.empty && opt.byKey.empty)
			return;

		write(ident, ("class" in opt)? opt["class"] : "LAMBDA", "(");
		foreach(op; opt.byKey)
			if(op != "class")
				write(op, "=", opt[op], " ");
		writeln(") {");

		foreach(ch; children)
			ch.print(ident~"  ");

		writeln(ident,"} // ", ("class" in opt)? opt["class"] : "LAMBDA");
	}
}

