import std.stdio;
import std.array;
import std.conv;
import std.algorithm;
import std.datetime;
import std.traits;
import std.range;
import post;
import view;


struct Fit
{
	int id;
	float fit;
	auto opBinary(op)(const ref Fit x)
	{
		static if(op == "<") return fit < x.fit;
	}
}


immutable auto dT=dur!"minutes"(30);


void main(string[] arg)
{
	File fd=stdin;
	if(arg.length > 1) fd.open(arg[1]);
	Post[uint] raw=parse(fd);
	fd.close;
	auto total=sum(raw.values);
	auto wgt=total.view(dT,total.at).smooth(50).normalize;
	View[int] data;
	foreach(post; raw) {
		if(post.start > 30 || post.end < 1440)
			raw.remove(post.id);
		else
			data[post.id]=post.view(dT, total.at).weight(wgt);
	}
	int[][int] grp;
	foreach(i, id; data.keys)
		grp[cast(int)i]~=id;
		
	grp=grp.iterate(data, total.at);
	grp=grp.iterate(data, total.at);
	stderr.writeln("clusters: ", grp.length);
	foreach(v; grp.values.sort!("a.length > b.length")) {
		stderr.writeln(v.length);
		writeln(join(v.map!(a=>to!string(a)),","));
	}
	
	
		
		
	
		
	
	
///////////// function end //////////////
	return;
}


int[][int] iterate(int[][int] grp, View[int] data, DateTime at)
{
	// sumarize groups
	View[int] sample;
	foreach(v; grp.byKeyValue) {
		sample[v.key]=summarize(v.value.map!(a=>data[a]), at);
	}
	// calc. groups cross fit
	Fit[][int] fit;
	foreach(i; 0..cast(int) sample.length) {
		foreach(k; i+1..cast(int) sample.length) {
			auto f=view.fit(sample[i], sample[k]);
			fit[i]~=Fit(k,f);
			fit[k]~=Fit(i,f);
		}
	}
	foreach(ref v; fit.byValue) v.sort!"a.fit < b.fit";

	int[][int] ngrp;
	
	for(int idx=0; fit.length; ++idx) {
		auto seed_v=float.max;
		int seed=seed(fit);
		int[int] cluster;
		
		// divide clusters
		cluster[seed]=0;
		while(clust(cluster, fit)) {}
		foreach(n; cluster.keys)
			fit.remove(n);
		
		foreach(i; cluster.keys) {
			ngrp[idx]~=grp[i];
		}
	}
	
	return ngrp;
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

int peer(int id, const ref Fit[][int] st)
{
	return st[id][0].id;
}


/+
static if(0) {	
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
+/

