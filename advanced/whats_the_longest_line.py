# python whats_the_longest_line.py LungOperational.sql
import sys
max_length = 0
the_line = ''
with open(sys.argv[1]) as fh:
    for L in fh:
        if len(L) > max_length:
            max_length = len(L)
            the_line = L
print(max_length)
print(the_line, end='')
