import sys
import re
assert sys.version_info.major >= 3

DEFAULT_COMMENT = '    --altered by Python'
fh = open(sys.argv[1])
vinci = re.compile(re.escape('VINCI1'), re.IGNORECASE)
ord_singh_src_all = re.compile("\[?ORD_Singh[^ -')]*Src[^ -')]*\]?", re.IGNORECASE)
ord_singh_src_stop = re.compile("\[?ORD_Singh[^ -')]*Src\]?", re.IGNORECASE)
ord_dflt = re.compile("\[?ORD_Singh[^ -')]*Dflt\]?", re.IGNORECASE)

for L in fh.read().splitlines():
    comment = ''
    if vinci.search(L) or ord_dflt.search(L):
        comment = DEFAULT_COMMENT
    if ord_singh_src_all.search(L):
        comment = '    --alert'
    L = ord_singh_src_stop.sub('[CDWWork]', L)
    L = vinci.sub('[CDWWork]', L)
    L = ord_dflt.sub('[MyDB].[MySchema]', L)
    print(L + comment)
