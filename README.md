# HNPFuzzer-ProFuzzBench

HNPFuzzer-ProFuzzBench provides automation scripts for fuzzing the 13 targets in ProFuzzBench with 4 fuzzers, i.e., [HNPFuzzer](https://github.com/veltavid/HNPFuzzer.git), [AFLnwe](https://github.com/aflnet/aflnwe), [AFLNet](https://github.com/aflnet/aflnet), and [StateAFL](https://github.com/stateafl/stateafl).

## Set up environmental variables

```bash
git clone https://github.com/veltavid/HNPFuzzer-ProFuzzBench.git
cd HNPFuzzer-ProFuzzBench
export PFBENCH=$(pwd)
export PATH=$PATH:$PFBENCH/scripts/execution:$PFBENCH/scripts/analysis
```

## Build docker images

```bash
profuzzbench_build_all.sh
profuzzbench_build_HNPFuzzer.sh
```

## Run fuzzing

It is easy to run a fuzzing experiment by using [run_target.sh](run_target.sh), which receives 7 arguments as listed below.

- ***-t***: name of the target to be fuzzed
- ***-r***: number of parallel runs
- ***-f***: fuzzer name
- ***-s***: (optional) time for fuzzing in seconds, 86400s (24h) by default.
- ***-m***: (optional) mode of HNPFuzzer (i.e., *persistent, shared, sync, all*). The activated components in HNPFuzzer vary among modes.
- ***-i***: (optional) the index of output folder.
- ***-o***: (optional) directory where to place the output folder.

The following commands show how to run a 24h fuzzing using HNPFuzzer with all components enabled on LightFTP.

```bash
cd $PFBENCH
./run_target.sh -t lightftp -r 1 -f HNPFuzzer -m all -o ./tmp_results
```

## Collect the results

This step is the same as the step-3 in [ProFuzzBench](https://github.com/profuzzbench/profuzzbench/tree/master#step-3-collect-the-results).

## Evaluate the results

The python script [experiments_plot.py](scripts/analysis/experiments_plot.py) can be used to plot code coverage over time. Its usage is similar to profuzzbench_plot.py in ProFuzzBench, except for the following extra options:

- ***-t***: interval of ticks on the x-axis

- ***-r***: (optional) name of the folder that contains results.csv. If this options is not provided, the script will jump to a folder named "results" under each application directory and perform step-3. Therefore, there is no need to generate results.csv by hand in the previous step.

The following command is an example to plot the results.

```bash
cd $PFBENCH
python experiments_plot.py -c 1450 -s 1 -t 200 -o cov_over_time.png -r results
```

