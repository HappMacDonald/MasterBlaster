# Usage:
# make [all]  # compile all binary
# make test   # run all tests
# make clean  # remove ALL binaries and build objects

.PHONY = all test clean
MKDIR			:= mkdir -p
RM				:= rm -rvf
CC      	:= gcc
BIN     	:= ./binaries
OBJ     	:= ./build
TEST_OBJ 	:= ./build
INCLUDE 	:= ./include
SRC     	:= ./sources
TEST_SRC	:= ./testSources
SRCS_c   	:= $(wildcard $(SRC)/*.c)
SRCS_S   	:= $(wildcard $(SRC)/*.S)
SRCS_s   	:= $(wildcard $(SRC)/*.s)
TEST_SRCS_c	:= $(wildcard $(TEST_SRC)/*.c)
TEST_SRCS_S	:= $(wildcard $(TEST_SRC)/*.S)
TEST_SRCS_s	:= $(wildcard $(TEST_SRC)/*.s)
OBJS_c  	:= $(patsubst $(SRC)/%,$(OBJ)/%,$(SRCS_c:.c=.c.o))
OBJS_S  	:= $(patsubst $(SRC)/%,$(OBJ)/%,$(SRCS_S:.S=.S.o))
OBJS_s  	:= $(patsubst $(SRC)/%,$(OBJ)/%,$(SRCS_s:.s=.s.o))
OBJS			:= $(OBJS_c) $(OBJS_S) $(OBJS_s)
TEST_OBJS_c	:= $(patsubst $(TEST_SRC)/%,$(TEST_OBJ)/%,$(TEST_SRCS_c:.c=.c.o))
TEST_OBJS_S	:= $(patsubst $(TEST_SRC)/%,$(TEST_OBJ)/%,$(TEST_SRCS_S:.S=.S.o))
TEST_OBJS_s	:= $(patsubst $(TEST_SRC)/%,$(TEST_OBJ)/%,$(TEST_SRCS_s:.s=.s.o))
TEST_OBJS		:= $(TESTOBJS_c) $(TESTOBJS_S) $(TESTOBJS_s)

CFLAGS  	:= -I$(INCLUDE)
AFLAGS		:= -I$(INCLUDE)
LDLIBS  	:= 

all:

test:

clean: 
	@echo "Cleaning up..."
	rm -rvf build/* bin/*
	