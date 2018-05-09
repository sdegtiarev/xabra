
PROG= xabrastat tagtree vue clust 
DOPT= -I$(HOME)/lib/D
DLIB= $(HOME)/lib/D/local/*.d 
all: $(PROG)


vue: vue.d post.d view.d 
	dmd $(DOPT) vue post.d view.d $(DLIB) 

clust: clust.d post.d view.d 
	dmd $(DOPT) clust post.d view.d $(DLIB) 

tagtree: tagtree.d loader.d
	dmd $(DOPT) tagtree loader.d $(DLIB)

xabrastat: xabrastat.d tagged.d 
	dmd $(DOPT) xabrastat tagged.d $(DLIB) 

v1: v1.d post.d view.d
	dmd $(DOPT) v1 post.d view.d $(DLIB) 

.PHONY: clean deinstall
clean:
	@ rm -f *.o core
deinstall:
	@ rm -f $(PROG)
