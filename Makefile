CC := gcc
ARCHS := -arch i386 -arch x86_64
CFLAGS := -c -std=c99 -O2 -pedantic -Wall -Wextra $(ARCHS) -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64
LD := gcc
LDFLAGS := $(ARCHS)

# TESTBIN needs to be a signed binary
TESTBIN := /bin/bash
TESTDIR := ./unsign-tests

all: unsign

unsign: unsign.o endian.o
	$(LD) $(LDFLAGS) $^ -o $@

endian.o: endian.c endian.h
	$(CC) $(CFLAGS) $< -o $@

unsign.o: unsign.c endian.h
	$(CC) $(CFLAGS) $< -o $@

test: all
	sh run-tests.sh ./unsign $(TESTBIN) $(TESTDIR)

clean:
	rm -f unsign endian.o unsign.o
	rm -rf $(TESTDIR)

.PHONY: all clean test
