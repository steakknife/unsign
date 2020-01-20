CC := gcc

DARWIN_VERSION := $(shell sw_vers -productVersion)
DARWIN_MOJAVE_AND_UP := $(shell expr $(DARWIN_VERSION) \>= 10.14)

# don't build for i386 on Mojave and up...
ifeq ($(DARWIN_MOJAVE_AND_UP),1)
ARCHS := -arch x86_64
else
ARCHS := -arch i386 -arch x86_64
endif

CFLAGS := -c -std=c99 -O2 -pedantic -Wall -Wextra $(ARCHS) -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64
LD := gcc
LDFLAGS := $(ARCHS)

unsign: unsign.o endian.o
	$(LD) $(LDFLAGS) $^ -o $@

endian.o: endian.c endian.h
	$(CC) $(CFLAGS) $< -o $@

unsign.o: unsign.c endian.h
	$(CC) $(CFLAGS) $< -o $@

clean:
	rm -f unsign endian.o unsign.o
