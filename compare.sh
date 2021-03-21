#!/bin/sh bash

read number;
re='^[0-9]+$'
done=0

if ! [[ $number =~ $re ]]; then
    echo "Contains letters!"
else
    while ! [ $done -eq 1 ]; do
        if [[ $number -eq 20 ]] || [[ $number -eq 40 ]];
        then
            done=1;
            echo "Yes, it's either 20 or 40.";
        else
            echo "No, it's not 20, nor 40.";
            read number;
        fi
        
    done
fi