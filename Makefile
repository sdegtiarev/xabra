


all: vue p1


# vue: vue.d view.d local/getopt.d local/spline.d
# 	dmd -g vue view.d local/spline.d local/getopt.d
vue: vue.d local/getopt.d local/spline.d
	dmd -g vue local/spline.d local/getopt.d

p1: p1.d post.d local/getopt.d
	dmd -g p1 post.d local/getopt.d


clean:
	@ rm -f *.o core
