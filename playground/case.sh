#!/usr/bin/bash

limit=0

while getopts ":L:c2r" opt; do
    case $opt in
        L) limit="$OPTARG"
        echo "limit is: $limit"
        for (( i=1; i<=limit; i++ )); do
            echo "current i: $i"
        done
        ;;
        c) echo "You chose mode c (count)"
        ;;
        2) echo "You chose mode 2 (last two)"
        ;;
        r) echo "You chose mode r (reverse)"
        ;;
        \?) echo "Invalid option -$OPTARG" >&2; exit 1
        ;;
    esac
done
shift $((OPTIND -1))

