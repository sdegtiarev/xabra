module loader;
import std.stdio;
import std.string;


string load(string file)
{
	string page;
	auto fd=File(file, "r");
	scope(exit) fd.close;
	foreach(line; fd.byLine(KeepTerminator.yes))
		page~=line;
	return page;
}


string load(File fd)
{
	string page;
	scope(exit) fd.close;
	foreach(line; fd.byLine(KeepTerminator.yes))
		page~=line;
	return page;
}
