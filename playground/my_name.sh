#!/usr/bin/bash


if [ -n "$1" ]; then
    name=$1
else
    echo "What is your name?"
    read -r name
fi

if [ -n "$2" ]; then
    age=$2
else
    echo "How old are you?"
    read -r age
fi

echo "Hello $name, you are $age years old."
