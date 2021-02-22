import sys
import re
assert sys.version_info.major >= 3

fh = open(sys.argv[1])
mydb_backref = re.compile("\[MyDB\]\.\[MySchema\]\.\[?(\w+)\]?", re.IGNORECASE)
#                              [MyDB].[MySchema].[asdfasdf]

for L in fh.read().splitlines():
    comment = ''
    m = mydb_backref.search(L)
    if m:
        comment = '    --altered (temp table)'
        table_name = m.group(1)                                                # '[inpat_inpatientcptprocedure]'
        L = mydb_backref.sub('#' + table_name, L)
    print(L + comment)
