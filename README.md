# lake-temperature-out
outputs and summaries from lake modeling pipelines

# Running models on USGS clusters

## Yeti quickstart

Once everything is set up (see below), log into Yeti and get started like this:
```sh
ssh yeti.cr.usgs.gov
cd /cxfs/projects/usgs/water/iidd/data-sci/lake-temp/lake-temperature-out
```

## Configure Yeti session to not change file permissions

One limitation we have discovered with default configurations in Yeti is that any time someone modifies a file, the file permissions change so that others are locked out. This made it really difficult to work collaboratively in one directory on Yeti, especially with git repos because whoever last pulled from upstream became the "owner" of any files modified from that pull. To get around this, you can set a configuration in your Yeti session so that any changes you make to a file will not modify the file's permissions. You will need to run the command below in every Yeti session that you start up. Note that this is not something you want to do if you are working on files that only you should be able to change, e.g. your id_rsa keys. 
```sh
umask 002
```

If you forget to do this in a session and end up modifying a file and change the permissions, you can restore permissions to others by running the code below to give read/write access to users in your group.
```sh
chmod g+w <filename or directory>
```


## Using Interactive:
make sure you belong to the watertemp group -or- use iidd (or cida) in place of it below:

```sh
salloc -A iidd -n 4 -p normal -t 7:00:00
```
this ☝️ gives you 4 cores on normal for 7 hours. You probably want way more than 4, but this is a start.
Then ssh into the node you are given, and from there, go to the working directory
```sh
ssh n3-98
cd /cxfs/projects/usgs/water/iidd/data-sci/lake-temp/lake-temperature-out
```
Load modules as before:
```sh
module load legacy R/3.6.3 tools/nco-4.7.8-gnu tools/netcdf-c-4.3.2-intel
```
then start R
```sh
R
```
Now you are in R but on a big cluster, so the number of cores you have available is much greater than on your own machine (unless you only asked for 4 cores...)
```sh
library(scipiper)
sbtools::authenticate_sb('cidamanager')
scmake('3_summarize/out/annual_metrics_pgdl.csv')
```

Note that `3_summarize.yml` will need to be modified to take advantage of loop tasks by specifying the number of cores to use. If the job fails or you are kicked off Yeti, no worries, as remake/scipiper will pick back up where you left off in the task table. 🎉

Lastly, the `glm2 pb0` runs have tons of lakes and were successfully run by NOT using an interactive R session. So, instead of starting R as it says in the steps above, add an R script called `run.R` that contains that following script and kick off at the command line by running `nohup Rscript run.R &`. The difference is that you can't use this method to log in to SB, so make sure `1_fetch` steps are complete first.

```r
# To kick this off, run the following in the command line instead of `R`
# `nohup Rscript run.R &`

message("Build with no login to SB")
library(scipiper)

message(sprintf("starting 3_summarize for glm2pb0 at %s", Sys.time()))
scmake("3_summarize/out/annual_metrics_glm2pb0.csv")

```

## Editing files on the cluster - Launching Jupyter Lab

You can use `vim` to edit files locally.

You can also use the Jupyter interface to edit files via a browser-based IDE. See https://hpcportal.cr.usgs.gov/hpc-user-docs/Yeti/Guides_and_Tutorials/how-to/Launch_Jupyter_Notebook.html for more.

Once you have set up a script to launch Jupyter Lab for the project and created the jlab environment for the user (see instructions below), follow these steps:

1. In a new terminal window (call this one Terminal #2, assuming you'll keep one open for terminal access to Yeti):
```sh
ssh yeti.cr.usgs.gov
cd /cxfs/projects/usgs/water/iidd/data-sci/lake-temp/lake-temperature-out
module load legacy
module load python/anaconda3
salloc -J jlab -t 2:00:00 -p normal -A iidd -n 1 -c 1
sh launch-jlab.sh
```
and copy the first line printed out by that script (begins with `ssh`). Note that this terminal is now tied up.

2. In another new terminal window (call this one Terminal #3), paste the ssh command, which will look something like this:
```sh
 ssh -N -L 8599:igskahcmgslih03.cr.usgs.gov:8599 hcorson-dosch@yeti.cr.usgs.gov
```
Enter the command. Note that this terminal is now tied up.

3. Copy one of the final URLs printed out by the launch-jlab.sh script in Terminal #2, and paste it into a local browser window. Will look like this:
```
http://igskmncmpshtl01:8528/?token=962bc58cf87016fa35075ecd64cec5597e805bd1ecbce0ca
```
Be patient as the interface loads. Once you're in, you can edit files, create notebooks, etc. with the Jupyter Lab IDE.

#### Creating a conda Jupyter Lab environment (once per user)
```sh
module load legacy
module load python/anaconda3
conda create -n jlab jupyterlab -c conda-forge
```

In order to add an R kernel to the Jupyter Lab IDE (so that we can build and run R notebooks in addition to Python notebooks), we need to run the following series of commands:
```sh
module load legacy
module load python/anaconda3
conda activate jlab
conda install -c r r-irkernel zeromq
```
If you have already set up Jupyter Lab for the project (see below) and launched Jupyter Lab, you will have to re-launch Jupyter Lab (see above) to see the R kernel.

#### Creating a script to launch Jupyter Lab (once per project)
Save the following script to `launch-jlab.sh`.

```sh
#!/bin/bash

JPORT=`shuf -i 8400-9400 -n 1` 

source activate jlab

echo "ssh -N -L $JPORT:`hostname`:$JPORT $USER@yeti.cr.usgs.gov"

jupyter lab --ip '*' --no-browser --port $JPORT --notebook-dir=. &

wait
```

Next we need to add the base R library from the Yeti R 3.6.3 module to our .Renviron file, so that it can be accessed by the Rkernel in Jupyter Lab.

In the console, within the project directory, type `vim .Renviron`. Enter 'i' to enter the insert mode, and paste in the following line:

```sh
R_LIBS_USER="/cxfs/projects/usgs/water/iidd/data-sci/lake-temp/lake-temperature-out/Rlib_3_6":"/opt/ohpc/pub/usgs/libs/gnu8/R/3.6.3/lib64/R/library"
```
Press 'Esc', then type ':wq' to save and close the file.

Launch Jupyter Lab (see above) and open a new Jupyter Notebook with the R kernel. Run the command `.libPaths()`. You should see these 3 paths listed in this order:
```sh
'/cxfs/projects/usgs/water/iidd/data-sci/lake-temp/lake-temperature-out/Rlib_3_6'
'/opt/ohpc/pub/usgs/libs/gnu8/R/3.6.3/lib64/R/library'
'/home/{username}/.conda/envs/jlab/lib/R/library'
```
Now we should be able to load any libraries from our project library folder while in Jupyter Lab, and any necessary dependencies that are not in our project library folder will be loaded from the Yeti R 3.6.3 module library.
