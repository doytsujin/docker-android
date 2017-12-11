#!/bin/bash

function start() {
    # BUILD and TESTNAME must be set by user in test desired_caps
    BUILD="$(curl -s localhost:4723/wd/hub/sessions | jq -r '.value[0].capabilities.BUILD')"
    TESTNAME="$(curl -s localhost:4723/wd/hub/sessions | jq -r '.value[0].capabilities.TESTNAME').mp4"
    mkdir -p $VIDEO_PATH/$BUILD
    echo "Start video recording"
    ffmpeg -video_size 1599x899 -framerate 15 -f x11grab -i $DISPLAY $VIDEO_PATH/$BUILD/$TESTNAME -y
}

function stop() {
    echo "Stop video recording"
    kill $(ps -ef | grep [f]fmpeg | awk '{print $2}')
}

function auto_record() {
    echo "Auto record: $AUTO_RECORD"
    sleep 6

    while [ $AUTO_RECORD == "True" ]; do
        # Check if there is test running
        no_test=true
        while $no_test; do
            task=$(curl -s localhost:4723/wd/hub/sessions | jq -r '.value')
            if [ "$task" == "" ] || [ "$task" == "[]" ]; then
                sleep .5
            else
                start &
                no_test=false
            fi
        done

        # Check if test is finished
        while [ $no_test == false ]; do
            task=$(curl -s localhost:4723/wd/hub/sessions | jq -r '.value')
            if [ "$task" == "" ] || [ "$task" == "[]" ]; then
                stop
                no_test=true
            else
                sleep .5
            fi
        done
    done

    echo "Auto recording is disabled!"
}

$@
