CC = gcc
CFLAGS = -Wall -DDEBUG=1 -DREVOLUTION=2048 -DGEAR_RATIO=2 -DMIN_INTERVAL=2453 -std=c99 -lm

ARCH := $(shell arch)

ifeq ($(findstring arm,$(ARCH)), arm)
CFLAGS += -lwiringPi
else
CFLAGS += -DEMULATE=1
endif

DEPS = src/spin.h

%.o: %.c $(DEPS)
	$(CC) $(CFLAGS) -c -o $@ $<

all: bin/smoothticker bin/step bin/ticker bin/swissticker

bin/step: src/step.o src/spin.o
	$(CC) $(CFLAGS) -o $@ $^

bin/ticker: src/ticker.o src/spin.o
	$(CC) $(CFLAGS) -o $@ $^

bin/smoothticker: src/smoothticker.o src/spin.o
	$(CC) $(CFLAGS) -o $@ $^

bin/swissticker: src/swissticker.o src/spin.o
	$(CC) $(CFLAGS) -o $@ $^

clean:
	rm -f bin/step bin/smoothticker bin/swissticker bin/ticker src/*.o
