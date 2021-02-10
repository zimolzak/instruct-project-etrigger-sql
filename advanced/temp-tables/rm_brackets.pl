#!/usr/bin/perl -w

# usage: ./rm_brackets.pl Lung_chicago.sql > out.sql

use strict;
while(<>){
    if (/is not null/i && /OBJECT/i) {
	s/\[//g;
	s/\]//g;
    }
    print;
}
