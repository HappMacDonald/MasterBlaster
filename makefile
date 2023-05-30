# Usage:
# make [all]  # compile all binary
# make test   # run all tests
# make clean  # remove ALL binaries and build objects

.PHONY = all test clean
MKDIR			:= mkdir -p
RM				:= rm -rvf
CC				:= gcc
BIN				:= ./binaries
OBJ				:= ./build
TEST_OBJ	:= ./build
INCLUDE		:= ./include
SRC				:= ./sources
TEST_SRC	:= ./testSources
SRCS_c		:= $(wildcard $(SRC)/*.c)
SRCS_S		:= $(wildcard $(SRC)/*.S)
SRCS_s		:= $(wildcard $(SRC)/*.s)
TEST_SRCS_c	:= $(wildcard $(TEST_SRC)/*.c)
TEST_SRCS_S	:= $(wildcard $(TEST_SRC)/*.S)
TEST_SRCS_s	:= $(wildcard $(TEST_SRC)/*.s)
OBJS_c		:= $(patsubst $(SRC)/%,$(OBJ)/%,$(SRCS_c:.c=.c.o))
OBJS_S		:= $(patsubst $(SRC)/%,$(OBJ)/%,$(SRCS_S:.S=.S.o))
OBJS_s		:= $(patsubst $(SRC)/%,$(OBJ)/%,$(SRCS_s:.s=.s.o))
OBJS			:= $(OBJS_c) $(OBJS_S) $(OBJS_s)
TEST_OBJS_c	:= $(patsubst $(TEST_SRC)/%,$(TEST_OBJ)/%,$(TEST_SRCS_c:.c=.c.o))
TEST_OBJS_S	:= $(patsubst $(TEST_SRC)/%,$(TEST_OBJ)/%,$(TEST_SRCS_S:.S=.S.o))
TEST_OBJS_s	:= $(patsubst $(TEST_SRC)/%,$(TEST_OBJ)/%,$(TEST_SRCS_s:.s=.s.o))
TEST_OBJS		:= $(TEST_OBJS_c) $(TEST_OBJS_S) $(TEST_OBJS_s)

CFLAGS		:= -I$(INCLUDE)
AFLAGS		:= -I$(INCLUDE) -fPIC -nostartfiles -nostdlib -Wall -g -ggdb -gdwarf-4 -g3 -F dwarf -m64
LDLIBS		:=

all:

test: $(BIN)/TestAnythingProtocolProducer.elf64

$(BIN)/TestAnythingProtocolProducer.elf64: $(TEST_SRC)/TestAnythingProtocolProducer.S $(SRC)/libmb_s.S $(INCLUDE)/libmb_s.h $(INCLUDE)/crude_compiler.h
	$(CC) $(AFLAGS) $(TEST_SRC)/TestAnythingProtocolProducer.S $(SRC)/libmb_s.S -o $(BIN)/TestAnythingProtocolProducer.elf64

clean:
	@echo $(TEST_OBJS)
	@echo "Cleaning up..."
	rm -rvf build/* bin/*
