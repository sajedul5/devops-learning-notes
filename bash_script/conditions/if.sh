#!/bin/bash

var1=1
var2=1

echo ".............................."
if [ $var1 ]; then
    echo "okkk"
fi
echo ".............................."
if [ $var1 == $var2 ]; then
    echo "equal"
else
    echo "why!"
fi
echo ".............................."
if [ $var1 != $var2 ]; then
    echo "not equal"
fi