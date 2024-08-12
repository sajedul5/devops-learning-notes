#!/bin/bash
 a=20
 b=20

echo ".............................."
if [ $a -eq $b ]; then
    echo "Equal"
else
    echo "Not Equal"
fi

echo ".............................."
if [ $a -ne $b ]; then
    echo " Equal "
else
    echo "Not Equal "
fi

echo ".............................."
if [ $a -gt $b ]; then
    echo " $a > $b"
else
    echo "not "
fi

echo ".............................."
if [ $a -lt $b ]; then
    echo "$a < $b"
else
    echo "not "
fi
