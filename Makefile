


all: vue clust


# vue: vue.d view.d local/getopt.d local/spline.d
# 	dmd -g vue view.d local/spline.d local/getopt.d
vue: vue.d post.d view.d local/getopt.d local/spline.d
	dmd -g vue post.d view.d local/spline.d local/getopt.d

clust: clust.d post.d view.d
	dmd -g clust post.d view.d

p1: p1.d post.d view.d local/getopt.d  local/spline.d
	dmd -g p1 post.d view.d local/getopt.d local/spline.d


clean:
	@ rm -f *.o core
