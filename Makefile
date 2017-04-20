
#all: vue clust
all: tagstat tagtree


# vue: vue.d view.d local/getopt.d local/spline.d
# 	dmd -g vue view.d local/spline.d local/getopt.d
vue: vue.d post.d view.d local/getopt.d local/spline.d
	dmd -g vue post.d view.d local/spline.d local/getopt.d

clust: clust.d post.d view.d local/getopt.d
	dmd -g clust post.d view.d local/getopt.d

p1: p1.d post.d view.d local/getopt.d  local/spline.d
	dmd -g p1 post.d view.d local/getopt.d local/spline.d

tagtree: tagtree.d loader.d
	dmd -g tagtree loader.d

tagstat: tagstat.d loader.d
	dmd -g tagstat loader.d


clean:
	@ rm -f *.o core
