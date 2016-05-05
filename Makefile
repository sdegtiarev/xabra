


all: vue #p1


# vue: vue.d view.d local/getopt.d local/spline.d
# 	dmd -g vue view.d local/spline.d local/getopt.d
vue: vue.d post.d view.d lview.d local/getopt.d local/spline.d
	dmd -g vue post.d view.d lview.d local/spline.d local/getopt.d

p1: p1.d post.d view.d local/getopt.d  local/spline.d
	dmd -g p1 post.d view.d local/getopt.d local/spline.d


clean:
	@ rm -f *.o core
