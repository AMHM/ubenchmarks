### If we are not compiling on an alpha, we must use cross tools ###    
CROSS_COMPILE=/share/pub/bdonyana/software/alphaev67-unknown-linux-gnu/4.3.2/alphaev67-unknown-linux-gnu/bin/
export CC=$(CROSS_COMPILE)g++
export AS=$(CROSS_COMPILE)as
export LD=$(CROSS_COMPILE)ld

export CFLAGS=-O2 -Wall -Werror -std=c++11
export OBJFLAGS=-static -pthread $(CFLAGS)

.PHONY: all clean veryclean predictors_clean predictors

all: test

clean:
	rm -rf bin obj

veryclean: predictors_clean clean

dirs: bin obj
bin:
	mkdir bin
obj:
	mkdir obj

obj/%.o: src/%.cc | dirs
	$(CC) $(CFLAGS) -c $< -o $@

obj/big_switch.h: src/gen_big_switch.py | dirs
	python src/gen_big_switch.py > obj/big_switch.h

obj/kernels_icache.o: obj/big_switch.h src/kernels_icache.cc | dirs
	$(CC) $(CFLAGS) -c src/kernels_icache.cc -o obj/kernels_icache.o

KERN_INT_SRC=src/kernels_macros.cc src/kernels_int.cc
KERN_FLOAT_SRC=$(KERN_INT_SRC) src/kernels_float.cc
KERN_TIMED_SRC=$(KERN_FLOAT_SRC) src/kernels_timed.cc
KERN_ICACHE_SRC=$(KERN_TIMED_SRC) src/kernels_icache.cc

KERN_INT_OBJ=$(patsubst src/%.cc,obj/%.o,$(KERN_INT_SRC))
KERN_FLOAT_OBJ=$(patsubst src/%.cc,obj/%.o,$(KERN_FLOAT_SRC))
KERN_TIMED_OBJ=$(patsubst src/%.cc,obj/%.o,$(KERN_TIMED_SRC))
KERN_ICACHE_OBJ=$(patsubst src/%.cc,obj/%.o,$(KERN_ICACHE_SRC))
export KERN_OBJS=$(KERN_ICACHE_OBJ)

test: bin/mem_test bin/ubenchmark_periodic bin/ubenchmark_timed bin/predictor_test

predictor_test: bin/predictor_test
	perf stat -e cycles,instructions,cache-references,cache-misses,branches,branch-misses -r 10 bin/predictor_test_noprint

bin/mem_test: obj/mem_test.o
	$(CC) $(OBJFLAGS) $^ -o $@

bin/ubenchmark_periodic: src/ubenchmark_periodic.cc obj/ubenchmark_periodic_main.o obj/ubenchmark_funcs.o $(KERN_INT_OBJ)
	$(CC) $(OBJFLAGS) $^ -o $@

bin/ubenchmark_periodic_beats: src/ubenchmark_periodic.cc obj/ubenchmark_periodic_main.o obj/ubenchmark_funcs.o $(KERN_INT_OBJ)
	$(CC) -DHAS_BEATS -I../mash/src $(OBJFLAGS) $^ -o $@

bin/ubenchmark_timed: obj/ubenchmark_timed.o obj/ubenchmark_timed_main.o obj/ubenchmark_funcs.o $(KERN_INT_OBJ)
	$(CC) $(OBJFLAGS) $^ -o $@	

bin/predictor_test: obj/predictor.o $(KERN_OBJS)
	$(CC) $(CFLAGS) -static -DITER_PRINT -DITER_high_ilp_cache_good_int=500 -DITER_high_ilp_cache_bad_int=500 -DITER_low_ilp_cache_good_int=500 -DITER_low_ilp_cache_bad_int=500 -DITER_low_ilp_cache_good_float=500 -DITER_low_ilp_cache_bad_float=500 -DITER_high_ilp_cache_good_float=500 -DITER_high_ilp_cache_bad_float=500 -DITER_low_ilp_icache_bad=500 -DITER_low_ilp_branches_deep=500 src/predictor_main.cc $^ -o $@
	$(CC) $(CFLAGS) -static -DITER_high_ilp_cache_good_int=500 -DITER_high_ilp_cache_bad_int=500 -DITER_low_ilp_cache_good_int=500 -DITER_low_ilp_cache_bad_int=500 -DITER_low_ilp_cache_good_float=500 -DITER_low_ilp_cache_bad_float=500 -DITER_high_ilp_cache_good_float=500 -DITER_high_ilp_cache_bad_float=500 -DITER_low_ilp_icache_bad=500 -DITER_low_ilp_branches_deep=500 src/predictor_main.cc $^ -o bin/predictor_test_noprint

predictors: obj/predictor.o $(KERN_OBJS) obj/makefile.predictors
	@$(MAKE) -C . -f obj/makefile.predictors bin_predictor

predictors_clean: obj/makefile.predictors
	@$(MAKE) -C . -f obj/makefile.predictors clean

obj/makefile.predictors: src/predictor_gen_makefile.py | dirs
	python src/predictor_gen_makefile.py > obj/makefile.predictors 

