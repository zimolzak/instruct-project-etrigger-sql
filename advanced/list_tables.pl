#!/usr/bin/perl -w
use strict;

while(<>){
    s/^\s+//;
    tr/[A-Z]/[a-z]/;
    s/  / /g;
    print if /create/i or /into/i or /update/i;
}
