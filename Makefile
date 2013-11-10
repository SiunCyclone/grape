TARGET = libOrange
SOURCES = $(wildcard ./import/orange/*.d)
LIBS = -I./Derelict3/import -L-L./Derelict3/lib/dmd

all:
	dmd -lib -O -release -inline -of$(TARGET) $(SOURCES) $(LIBS)
	mv $(TARGET).a lib

