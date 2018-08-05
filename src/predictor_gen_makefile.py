#!/usr/bin/python

make=(
"\n"
"bin_predictor: obj/predictor.o $(KERN_OBJS) src/predictor_main.cc\n"
"\trm -rf bin_predictor\n"
"\tmkdir bin_predictor\n"
)

makePredTemplate="\t$(CC) $(CFLAGS) -static -DITER_high_ilp_cache_good_int=XXhigh_ilp_cache_good_intXX -DITER_high_ilp_cache_bad_int=XXhigh_ilp_cache_bad_intXX -DITER_low_ilp_cache_good_int=XXlow_ilp_cache_good_intXX -DITER_low_ilp_cache_bad_int=XXlow_ilp_cache_bad_intXX -DITER_low_ilp_cache_good_float=XXlow_ilp_cache_good_floatXX -DITER_low_ilp_cache_bad_float=XXlow_ilp_cache_bad_floatXX -DITER_high_ilp_cache_good_float=XXhigh_ilp_cache_good_floatXX -DITER_high_ilp_cache_bad_float=XXhigh_ilp_cache_bad_floatXX -DITER_low_ilp_icache_bad=XXlow_ilp_icache_badXX -DITER_low_ilp_branches_deep=XXlow_ilp_branches_deepXX src/predictor_main.cc obj/predictor.o $(KERN_OBJS) -o bin_predictor/XXpredictornameXX\n"

clean=(
"\n"
"clean:\n"
"\trm -rf bin_predictor\n")

benchname = []
benchIters = []

benchname.append("high_ilp_cache_good_int")
benchIters.append(["0","3840000","7680000"])

benchname.append("high_ilp_cache_bad_int")
benchIters.append(["0","480000"])

benchname.append("low_ilp_cache_good_int")
benchIters.append(["0","1290000"])

benchname.append("low_ilp_cache_bad_int")
benchIters.append(["0","990000"])

benchname.append("low_ilp_cache_good_float")
benchIters.append(["0","1070000"])

benchname.append("low_ilp_cache_bad_float")
benchIters.append(["0","880000"])

benchname.append("high_ilp_cache_good_float")
benchIters.append(["0","2560000"])

benchname.append("high_ilp_cache_bad_float")
benchIters.append(["0","480000"])

benchname.append("low_ilp_icache_bad")
benchIters.append(["0","1900000"])

benchname.append("low_ilp_branches_deep")
benchIters.append(["0","3500000"])

predIdx = 0
def combine(benchIdx,template):
    if(benchIdx >= len(benchname)):
        global make
        global predIdx
        predName = "predictor{:04d}".format(predIdx)
        template = template.replace("XXpredictornameXX", predName)
        make += template
        predIdx += 1
    else:
        for nIter in benchIters[benchIdx]:
            name = benchname[benchIdx]
            templateNew = template.replace("XX"+name+"XX",nIter)
            combine(benchIdx+1,templateNew)

combine(0,makePredTemplate)

make += clean

print make            



    
