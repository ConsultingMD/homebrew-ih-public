#!/bin/bash

black() {
    printf "\e[30m%b\e[0m" "$1"
}

red() {
    printf "\e[31m%b\e[0m" "$1"
}

green() {
    printf "\e[32m%b\e[0m" "$1"
}

yellow() {
    printf "\e[33m%b\e[0m" "$1"
}

blue() {
    printf "\e[34m%b\e[0m" "$1"
}

magenta() {
    printf "\e[35m%b\e[0m" "$1"
}

cyan() {
    printf "\e[36m%b\e[0m" "$1"
}

gray() {
    printf "\e[90m%b\e[0m" "$1"
}