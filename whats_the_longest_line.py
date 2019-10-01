# python whats_the_longest_line.py LungOperational.sql
import sys
fh = open(sys.argv[1])
max_length = 0
the_line = ''
for L in fh.read().splitlines():
    if len(L) > max_length:
        max_length = len(L)
        the_line = L
print(max_length)
print(the_line)
