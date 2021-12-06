#!/bin/bash

black() {
    printf "\e[30m%s\e[0m\n" "$1"
}

red() {
    printf "\e[31m%s\e[0m\n" "$1"
}

green() {
    printf "\e[32m%s\e[0m\n" "$1"
}

yellow() {
    printf "\e[33m%s\e[0m\n" "$1"
}

blue() {
    printf "\e[34m%s\e[0m\n" "$1"
}

magenta() {
    printf "\e[35m%s\e[0m\n" "$1"
}

cyan() {
    printf "\e[36m%s\e[0m\n" "$1"
}

gray() {
    printf "\e[90m%s\e[0m\n" "$1"
}