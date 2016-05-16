import std.stdio;
import std.array;
import std.conv;
import std.algorithm;

struct IDPair
{
	int id1, id2;
	
	this(int id1, int id2)
	{
		if(id1 < id2) { this.id1=id1; this.id2=id2; }
		else { this.id1=id2; this.id2=id1; }
	}
	this(T)(T[] id)
	{
		this(to!int(id[0]), to!int(id[1]));
	}
	
	size_t toHash() const @safe pure nothrow
	{
		size_t hash=id1;
		return (hash<<32)|id2;
	}
    bool opEquals(ref const IDPair x) const @safe pure nothrow
    {
    	return id1 == x.id1 && id2 == x.id2;
    }
}


struct Fit
{
	int id;
	float fit;
	auto opBinary(op)(const ref Fit x)
	{
		static if(op == "<") return fit < x.fit;
	}
}

void main(string[] arg)
{
	File fd=stdin;
	if(arg.length > 1) fd.open(arg[1]);
	
	
	Fit[][int] st;
	float seed_v=float.max;
	foreach(line; fd.byLine) {
		auto v=split(line);
		assert(v.length == 3);
		auto id=to!int(v[0]);
		auto peer=to!int(v[1]);
		auto fit=to!float(v[2]);

		st[id]~=Fit(peer, fit);
	}
	fd.close();
	foreach(ref v; st.byValue) v.sort!"a.fit < b.fit";
	
	int[int] id;
	int seed_id=seed(st);
	
	while(st.length) {
		id.clear;
		seed_id=seed(st);
		id[seed_id]=0;
		//writeln("test: fit[",seed_id,"] = ", st[seed_id][0]," map ", st.length);
		while(clust(id, st)) {}
		foreach(n; id.keys) st.remove(n);
		writeln(join(id.keys.map!(a=>to!string(a)),","));
		//stderr.writeln("left ", st.length);
	}
	
}

int peer(int id, const ref Fit[][int] st)
{
	return st[id][0].id;
}

int seed(const ref Fit[][int] st)
{
	auto seed_v=float.max;
	int seed=0;
	foreach(l; st) {
		foreach(fit; l) {
			if(fit.fit < seed_v) { seed_v=fit.fit; seed=fit.id; }
		}
	}
	return seed;
}


auto clust(ref int[int] ids, const ref Fit[][int] st)
{
	auto hit=ids.length;
	foreach(id; ids.byKey) {
		foreach(n; st.byKey) {
			if(peer(n,st) == id)
				ids[n]++;
		}
	}
	return hit != ids.length; 
}