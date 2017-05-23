CC := gcc
ARCHS := -m64
CFLAGS := -c -std=c99 -O2 -pedantic -I cctools/include -Wall -Wextra $(ARCHS) -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64
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
