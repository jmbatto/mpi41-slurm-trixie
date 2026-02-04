CC=gcc
XMPCC=xmpcc
LIBS=-L/usr/lib -lmpi
INCL=-I /usr/lib/openmpi/include
OBJM=manager-spawn.o 
OBJW=init.o

all: manager worker_program

manager-spawn.o: manager-spawn.c
	$(CC) -c $(INCL) manager-spawn.c

init.o: init.c
	$(XMPCC) -c init.c -I/home/ymlusr/local/var/yml/DefaultExecutionCatalog/generators/XMP/include -I/home/ymlusr/local/include

manager: $(OBJM)
	$(CC) -o manager $(OBJM) $(LIBS) 

worker_program: $(OBJW)
	$(XMPCC) -o worker_program $(OBJW) $(LIBS)

clean:
	rm *.o manager worker_program
