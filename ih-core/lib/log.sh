#!/bin/bash

ih::log::debug() {
    if [[ $IH_DEBUG = 1 ]]; then 
        printf "\e[90mDBUG: %s\e[0m\n" "$1"
    fi
}

ih::log::info() {
    printf "\e[34mINFO: %s\e[0m\n" "$1"
}

ih::log::warn() {
    printf "\e[33mWARN: %s\e[0m\n" "$1"
}

ih::log::error() {
    printf "\e[31mFAIL: %s\e[0m\n" "$1"
}