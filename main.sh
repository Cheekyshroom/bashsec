#!/usr/bin/env bash

if [ ! -d .tmp ]; then 
  mkdir .tmp
  mkdir .tmp/snaps
fi
if [ ! -d det ]; then mkdir det; fi
if [ ! -e .session ]; then echo 0 > .session; fi
if [ ! -e detectmotion ]; then make; fi

# increment session id
session=$(cat .session)
((session += 1))
echo "$session" > .session
mkdir det/$session

grab_frame() {
  echo "screenshot 0" > mpl-in
  sleep .2
  if [ "$(ls -1 | grep png)" == "" ]; then sleep .2; fi
  mv *.png .tmp/foo.png
  convert .tmp/foo.png -compress none "$1"
}

snippet_id=1
record_snippet() {
  echo "screenshot 1" > mpl-in
  sleep 6
  echo "screenshot 1" > mpl-in
  sleep .3
  # convert -delay 10 -adjoin shot* "$1"
  # we're deferring this convert to the end of the process
  # since it's the costliest step
  mkdir ".tmp/snaps/$snippet_id"
  mv shot* ".tmp/snaps/$snippet_id"
  echo "$1" > ".tmp/snaps/$snippet_id/name"
  convert_snippet ".tmp/snaps/$snippet_id" &
  ((snippet_id++))
}

convert_snippet() {
  echo "Working on $1"
  name=$(cat "$1/name")
  convert -delay 2 -adjoin $1/*.png "det/$session/$name.mp4"
}

# Spin up our mplayer instance
mkfifo mpl-in
sleep 100d > mpl-in &
echo $! > sleep-pid
cat mpl-in | mplayer -tv width=120:height=60 \
  -really-quiet \
  -slave \
  -vf screenshot \
  tv://device=/dev/video0 2> /dev/null &
echo $! > cat-pid
sleep 3

echo "Spun up, beginning detection"

# quit by hitting ^c
trap "{
  echo Exiting;
  kill -9 $(cat sleep-pid);
  kill -9 $(cat cat-pid);
  rm -f *-pid mpl-in;
  rm -f *.ppm *.gif *.png;
  rm -rf .tmp;
  exit 0;
}" SIGINT SIGTERM
  #for dir in .tmp/snaps/*; do
  #  convert_snippet \"\$dir\"
  #done;

grab_frame "previous.ppm"

while true; do
  grab_frame "current.ppm"
  if ./detectmotion "previous.ppm" "current.ppm"; then
    date=$(date)
    echo "Motion detected on $date"
    record_snippet "$date"
  fi
  mv "current.ppm" "previous.ppm"
done

