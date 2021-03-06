#!/bin/bash

# default values
export LED_LIGHT="scrolllock" # default to scroll lock
export LED_REPEAT=1           # default led_blink repeats
export LED_ON=0.5             # default led_blink ON time in seconds
export LED_OFF=0.5            # default led_blink OFF time in seconds

function led_set() {
    light -L 2>/dev/null \
        | rg "sysfs/leds/" \
        | rg -i "${1:-${LED_LIGHT}}" \
        | sed "s|\t||g" \
        | while read light
        do
            light -Srs ${light} ${2:-1} 2>/dev/null
        done
}

function led_get() {
    light -L 2>/dev/null \
        | rg "sysfs/leds/" \
        | rg -i "${1:-${LED_LIGHT}}" \
        | sed "s|\t||g" \
        | while read light
        do
            echo "${light} $(light -Grs ${light} 2>/dev/null)"
        done
}

function led_on() {
    led_set "${1:-${LED_LIGHT}}" 1
}

function led_off() {
    led_set "${1:-${LED_LIGHT}}" 0
}

function led_toggle() {
    led_get "${1:-${LED_LIGHT}}" \
        | while read light_state
        do
            light=$(echo "${light_state}" | cut -d' ' -f1)
            state=$(echo "${light_state}" | cut -d' ' -f2)
            light -Srs "${light}" "$( if [ "${state}" -eq 0 ]; then echo 1 ; else echo 0 ; fi )" 2>/dev/null
        done
}

function led_blink() {
    local LED_LIGHT=${1:-${LED_LIGHT}}
    local LED_REPEAT=${2:-${LED_REPEAT}}
    local LED_ON=${3:-${LED_ON}}
    local LED_OFF=${4:-${LED_OFF}}
    local re='^[0-9]+$'
    #echo "led_blink: light:${LED_LIGHT}, repeat:${LED_REPEAT}, on:${LED_ON}, off:${LED_OFF}"
    if [[ "${LED_REPEAT}" =~ ${re} ]] ; then
        (
        for i in $(seq 1 ${LED_REPEAT}); do
            if [ ${i} -eq 1 ]; then
                LED_WAIT=0
            else
                LED_WAIT=$( echo "(${LED_ON}+${LED_OFF})*(${i}-1)" | bc )
            fi
            (
                sleep ${LED_WAIT}
                led_on ${LED_LIGHT}
                sleep ${LED_ON}
                led_off ${LED_LIGHT}
                sleep ${LED_OFF}
            ) &
        done
        wait
        )
    else
        while true ; do
            led_on ${LED_LIGHT}
            sleep ${LED_ON}
            led_off ${LED_LIGHT}
            sleep ${LED_OFF}
        done
    fi
}

usage() {
    echo "${0} Halp."
    echo "-l   --list"
    echo "-o   --on"
    echo "-O   --off"
    echo "-b   --blink <repeat>"
    echo "-d   --blink-duration <seconds>"
    echo "-t   --toggle"
}

if [[ $# -eq 0 ]]; then
    NO_ARGS=1
fi

while (($#>0)); do
    case $1 in
        -o|--on)
            ON=1
            shift;;
        -O|--off)
            OFF=1
            shift;;
        -b|--blink)
            shift
            BLINK=${1}
            shift;;
        -d|--blink-duration)
            shift
            DURATION=${1}
            shift;;
        -l|-g|--list|--get)
            LIST=1
            shift;;
        -t|--toggle)
            TOGGLE=1
            shift;;
        -h|--help)
            usage
            exit
            ;;
        *)
            DEFAULT_LED_LIGHT=${1}
            shift;;
    esac
done

if [ ! -z "${LIST}" ]; then
    led_get .
elif [ ! -z "${OFF}" ]; then
    led_off ${DEFAULT_LED_LIGHT:-${LED_LIGHT}}
elif [ ! -z "${ON}" ]; then
    led_on ${DEFAULT_LED_LIGHT:-${LED_LIGHT}}
elif [ ! -z "${TOGGLE}" ]; then
    led_toggle ${DEFAULT_LED_LIGHT:-${LED_LIGHT}}
elif [ ! -z "${BLINK}" ] || [ ! -z "${DEFAULT_LED_LIGHT}" ]; then
    led_blink ${DEFAULT_LED_LIGHT:-${LED_LIGHT}} "${BLINK}" "${DURATION}" "${DURATION}"
elif [ ! -z "${NO_ARGS}" ]; then
    led_blink
fi

