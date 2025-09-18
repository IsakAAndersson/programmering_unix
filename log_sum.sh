#!/usr/bin/bash

filename="thttpd.log"

modes=()
limit=0

while getopts ":L:c2rFt" opt; do
  case $opt in
    L) limit="$OPTARG" #Limit nr of rows
    ;;
    c) modes+=("c") #IP adresses - Most connection attempts 
    ;;
    2) modes+=("2") #IP adresses - Most number of successful attempts
    ;;
    r) modes+=("r") #Most common result codes and where they come from
    ;;
    F) modes+=("F") #Most common result codes that result in failure and where they come from
    ;;
    t) modes+=("t") #IP numbers that get the most bytes sent to them
    ;;
    \?) echo "Invalid option -$OPTARG" >&2; exit 1
    ;;
  esac
done
shift $((OPTIND -1))

filename=$1

if [ -z "$filename" ]; then
    echo "Please provide a log file."
    exit 1
elif [ ! -f "$filename" ]; then
    echo "File not found!"
    exit 1
else
    echo "Using log file: $filename"
fi

for mode in "${modes[@]}"; do
    case $mode in
        c)
            printf "The IP adresses that makes the most number of connection attempts are: \n"
            if [ "$limit" -ne 0 ]; then
                awk '{print $1}' "$filename" | sort | uniq -c | sort -nr | awk '{printf "%-16s %5d\n", $2, $1}' | head -n "$limit"
            else
                awk '{print $1}' "$filename" | sort | uniq -c | sort -nr | awk '{printf "%-16s %5d\n", $2, $1}'
            fi
        ;;
        2)
            printf "The Ip adresses that makes the most amount of succesful connection attempts are: \n"
            if [ "$limit" -ne 0 ]; then
                awk '$9 == 200 {print $1}' "$filename" | sort | uniq -c | sort -nr | awk '{printf "%-16s %5d\n", $2, $1}' | head -n "$limit"
            else
                awk '$9 == 200 {print $1}' "$filename" | sort | uniq -c | sort -nr | awk '{printf "%-16s %5d\n", $2, $1}'
            fi
        ;;
        r)
            printf "The most common result codes and where they come from are:\n"
            if [ "$limit" -ne 0 ]; then
                top_codes=$(awk '{print $9}' "$filename" | sort | uniq -c | sort -nr | head -n "$limit" | awk '{print $2}')

                for code in $top_codes; do
                    echo ""
                    awk -v c="$code" '$9 == c {print $1}' "$filename" \
                        | sort | uniq -c | sort -nr | head -n "$limit" \
                        | awk -v cc="$code" '{printf "%-6s %-16s %5d\n", cc, $2, $1}'
                done
            else
                awk '{print $9, $1}' "$filename" | sort | uniq -c | sort -nr | \
                awk '{printf "%-6s %-16s %5d\n", $2, $3, $1}'
            fi
        ;;
        F)
            printf "The most common result codes that result in failure and where they come from are: \n"
            if [ "$limit" -ne 0 ]; then
                top_error_codes=$(awk '$9 ~ /^[45]/ {print $9}' "$filename" | sort | uniq -c | sort -nr | head -n "$limit" | awk '{print $2}')
                for code in $top_error_codes; do
                    echo ""
                    awk -v c="$code" '$9 == c {print $1}' "$filename" \
                        | sort | uniq -c | sort -nr | head -n "$limit" \
                        | awk -v cc="$code" '{printf "%-6s %-16s %5d\n", cc, $2, $1}'
                done    
            else
                awk '$9 ~ /^[45]/ {print $9, $1}' "$filename" | sort | uniq -c | sort -nr | awk '{printf "%-16s %5d\n", $2, $3, $1}'
            fi

        ;;
        t)
            printf "The IP numbers that get the most bytes sent to them are: \n"
            if [ "$limit" -ne 0 ]; then
                awk '{bytes[$1] += $10} END {for (ip in bytes) printf "%-16s %12d\n", ip, bytes[ip]}'\
                    "$filename" | sort -k2 -nr | head -n "$limit"
            else
                awk '{bytes[$1] += $10} END {for (ip in bytes) printf "%-16s %12d\n", ip, bytes[ip]}'\
                    "$filename" | sort -k2 -nr
            fi
        ;;
        *) echo "Unknown mode: $mode"
        ;;
    esac
done