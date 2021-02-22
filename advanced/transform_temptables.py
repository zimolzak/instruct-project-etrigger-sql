import sys
import re
assert sys.version_info.major >= 3

fh = open(sys.argv[1])
mydb_backref = re.compile("\[MyDB\]\.\[MySchema\]\.\[?(\w+)\]?", re.IGNORECASE)
#                              [MyDB].[MySchema].[table_name]

for L in fh.read().splitlines():
    comment = ''
    m = mydb_backref.search(L)
    if m:
        table_name = m.group(1)
        if 'OBJECT_ID' in L:
            comment = ' --altered (object_id temp table)'
            L = mydb_backref.sub('tempdb.dbo.#' + table_name, L)
        else:
            comment = ' --altered (temp table)'
            L = mydb_backref.sub('#' + table_name, L)
    print(L + comment)
