OBJS = QmiWwanCM.o GobiNetCM.o main.o MPQMUX.o QMIThread.o util.o udhcpc.o

CC:= $(CROSS-COMPILE)gcc
LD:= $(CROSS-COMPILE)ld
OUT_BIN = longsung-cm.bin

dep_file = .$@.d



all: $(OBJS)

		$(CC) -pthread $(LDFLAGS) -g -o $(OUT_BIN) $^



%.o: %.c

		$(CC) $(CFLAGS) -Wp,-MD,$(dep_file) -c -o $@ $<



clean:

	rm -rf *.o

	rm -rf $(OUT_BIN)

	rm -f $(shell find -name "*.d")
