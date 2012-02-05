#!/bin/sh

# see readme.txt for copyright info

# CONFIGURATION:

# command for RenderMan shader compiler
SHADER='shaderdl'

# command for RenderMan renderer
RENDER='renderdl'

# note: you are responsible for setting $PATH and $RMANTREE
# appropriately so that 'prman' will work.

# any extra flags you want to pass to prman
RENDERFLAGS='-progress'

# file for output of benchmark run
OUTPUT='output.txt'

#####################

# Gracefully exit on Ctrl-C and remove all temporary files
trap 'echo "Aborted." ; rm -f TEMP TIME SYSTEM_PROFILE; exit 1' TERM INT

# start time (for reporting use only, not for timing)
DATE=`date`

# determine operating system and # of CPUs
PLATFORM=`uname`

if [ "$PLATFORM" = "Linux" ]; then
    echo "Detected OS: Linux"
    CPUS=`grep processor /proc/cpuinfo | wc -l | sed 's/^[ \t]*//'`
elif [ "$PLATFORM" = "Darwin" ]; then
    echo "Detected OS: Mac OSX"
	CPUS=`sysctl -n machdep.cpu.core_count`
else
    echo "This script is not compatible with this OS: $PLATFORM"
    echo "Compile bench.sl and manually render each RIB file (except geom.rib)."
    echo "For timing, uncomment the \"Option\" line at the top of each RIB."
    exit 1
fi

if [ $CPUS -eq 1 ]; then
    echo "Detected 1 CPU"
elif [ $CPUS -gt 1 ]; then
    echo "Detected $CPUS CPUs"
fi

# test for presence of /usr/bin/time
if [ ! -x /usr/bin/time ]; then
    echo "/usr/bin/time is not available - please install it."
    echo "(on RedHat, install the 'time' RPM, on SuSE, install 'util-linux')"
    echo "(on Debian, install the 'time' package)"
    exit 1
fi

# compile the shader
echo "Compiling shader..."
if ! "$SHADER" bench.sl; then
    echo "Error compiling shader bench.sl"
    exit 1
fi

# usage:
# timerender "shader" foo.rib 2
# arg1: user-visible name of this test
# arg2: RIB file to render
# arg3: # of processors to use
# puts elapsed wall-clock time in seconds in a file called TIME

function timerender {
    echo "Running $1 benchmark "
  
    if [ $3 -eq 1 ]; then
	echo "(one thread)..."
    elif [ $3 -gt 1 ]; then
	echo "(multithreading)..."
    else
	echo "# of threads must be 1 or more (was $3)"
	exit 1
    fi

    # run renderer
    if [ "$PLATFORM" = "Linux" ]; then
	/usr/bin/time -f %e -o TIME "$RENDER" $RENDERFLAGS -p:$3 $2
    elif [ "$PLATFORM" = "Darwin" ]; then
	# Mac OSX's time(1) command has no ability to output to a file
	# so, redirect stderr to TEMP, then strip off everything but
	# the wall clock time in seconds. We must run the renderer
	# in a subshell in order to send its stderr to the console rather
	# than the TEMP file.
	/usr/bin/time sh -c "'$RENDER' $RENDERFLAGS -p:$3 $2 2>&1 " 2>TEMP && \
	(sed 's/ real.*//' | sed 's/^[ \t]*//') < TEMP > TIME && rm TEMP
    fi

    # check return value from the render
    if [ ! $? ]; then
	echo "Error running $1 benchmark"
	exit 1
    fi
    local RESULT=`cat TIME`
    echo "$1 benchmark done: $RESULT sec"
}

echo "Running single thread benchmarks..."
timerender "shader" shader.rib 1
SHADERTIME=`cat TIME`

timerender "shader_vm" shader_vm.rib 1
SHADERVMTIME=`cat TIME`

timerender "hider" hider.rib 1
HIDERTIME=`cat TIME`

timerender "diffuse raytrace" raydiff.rib 1
RAYDIFFTIME=`cat TIME`

timerender "diffuse raytrace with displacements" raydiff_displacements.rib 1
RAYDIFFDISPTIME=`cat TIME`

timerender "diffuse raytrace with displacements" raydiff_shade.rib 1
RAYDIFFSHADETIME=`cat TIME`

timerender "specular raytrace" rayspec.rib 1
RAYSPECTIME=`cat TIME`

if [ $CPUS -gt 1 ]; then
    echo "Running multithread benchmarks..."
    timerender "shader" shader.rib $CPUS
    DUALSHADERTIME=`cat TIME`

    timerender "shader_vm" shader_vm.rib $CPUS
    DUALSHADERVMTIME=`cat TIME`

    timerender "hider" hider.rib $CPUS
    DUALHIDERTIME=`cat TIME`

    timerender "diffuse raytrace" raydiff.rib $CPUS
    DUALRAYDIFFTIME=`cat TIME`

    timerender "diffuse raytrace with displacements" raydiff_shade.rib $CPUS
    DUALRAYDIFFSHADETIME=`cat TIME`

    timerender "diffuse raytrace with displacements" raydiff_displacements.rib $CPUS
    DUALRAYDIFFDISPTIME=`cat TIME`

    timerender "specular raytrace with displacements" rayspec.rib $CPUS
    DUALRAYSPECTIME=`cat TIME`
fi

echo "All benchmarks done."

# print output

cat > "$OUTPUT" <<EOF
RenderMan Benchmark v3
by Maas Digital LLC
(11 November 2004)

Run on $HOSTNAME at $DATE
Render command was $RENDER $RENDERFLAGS
EOF

# print renderer version
$RENDER -version >> "$OUTPUT" 2>&1
echo >> "$OUTPUT" # add a newline

# determine system info
if [ "$PLATFORM" = "Linux" ]; then
    # Linux
    echo "Gathering system info..."
    OS=`uname -s -r`
    NCPUS=`grep '^processor' /proc/cpuinfo | wc -l | sed 's/^[ \t]*//'`
    CPUTYPE=`grep model\ name /proc/cpuinfo  | head -n 1 | sed 's/.*: //'`
    CPUSPD=`grep cpu\ MHz /proc/cpuinfo  | head -n 1 | sed 's/.*: //'`
    CPUCACHE=`grep cache\ size /proc/cpuinfo | head -n 1 | sed 's/.*: //'`
    cat >> "$OUTPUT" <<EOF
System Info
-----------
OS:          $OS
# of CPUs:   $NCPUS (including HyperThreading virtual CPUs)
CPU type:    $CPUTYPE
CPU speed:   $CPUSPD MHz
CPU cache:   $CPUCACHE
EOF
elif [ "$PLATFORM" = "Darwin" ]; then
    # Mac OSX (use the file generated above with system_profiler)
    cat SYSTEM_PROFILE | head -n 12 >> "$OUTPUT"
fi

cat >> "$OUTPUT" <<EOF

Single thread Benchmarks
------------------------
Shader time:             $SHADERTIME sec
Shader VM time:          $SHADERVMTIME sec
Hider time:              $HIDERTIME sec
Diffuse raytrace time:   $RAYDIFFTIME sec
Diffuse raytrace+disp time:   $RAYDIFFDISPTIME sec
Diffuse raytrace+shade time:   $RAYDIFFSHADETIME sec
Specular raytrace time:  $RAYSPECTIME sec

EOF

if [ $CPUS -gt 1 ]; then
    cat >> "$OUTPUT" <<EOF
Multithread Benchmarks
----------------------
Shader time:             $DUALSHADERTIME sec
Shader VM time:          $DUALSHADERVMTIME sec
Hider time:              $DUALHIDERTIME sec
Diffuse raytrace time:   $DUALRAYDIFFTIME sec
Diffuse raytrace+disp time:   $DUALRAYDIFFDISPTIME sec
Diffuse raytrace+shade time:   $DUALRAYDIFFSHADETIME sec
Specular raytrace time:  $DUALRAYSPECTIME sec

EOF
fi

# append checksums of various files, to make sure
# they were not modified
echo "Checksums:" >> "$OUTPUT"

function do_md5sum {
    if [ "$PLATFORM" = "Linux" ]; then
        # Linux
	md5sum "$@"
    elif [ "$PLATFORM" = "Darwin" ]; then
       # Mac OSX (munge md5 output to look like md5sum)
	md5 "$@" | sed 's#MD5 (\(.*\)) = \(.*\)#\2  \1#'
    fi
}

do_md5sum bench.sl shader.rib raydiff.rib rayspec.rib hider.rib geom.rib >> $OUTPUT
do_md5sum $OUTPUT >> $OUTPUT

# clean up
rm -f TEMP TIME SYSTEM_PROFILE

echo "Done. See results in $OUTPUT."
