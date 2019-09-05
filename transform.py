import sys
import re
assert sys.version_info.major >= 3

DEFAULT_COMMENT = '    --altered by Python'
fh = open(sys.argv[1])
vinci = re.compile(re.escape('VINCI1'), re.IGNORECASE)
ord_singh_src_all = re.compile("\[?ORD_Singh[^ -')]*Src[^ -')]*\]?", re.IGNORECASE)
ord_singh_src_stop = re.compile("\[?ORD_Singh[^ -')]*Src\]?", re.IGNORECASE)
ord_singh_src_backref = re.compile("\[?ORD_Singh[^ -')]*Src\]?\\.(\[?\w+\]?)", re.IGNORECASE)
#                                    [ ORD_Singh.....].[Src ]   . [  a_b  ]
ord_dflt = re.compile("\[?ORD_Singh[^ -')]*Dflt\]?", re.IGNORECASE)

for L in fh.read().splitlines():
    comment = ''
    if vinci.search(L) or ord_dflt.search(L):
        comment = DEFAULT_COMMENT
    if ord_singh_src_all.search(L):
        comment = '    --alert'
        m = ord_singh_src_backref.search(L)
        underscores = m.group(1)                                                # '[inpat_inpatientcptprocedure]'
        dots = underscores.replace('_', '.', 1).replace('[','').replace(']','') # 'inpat.inpatientcptprocedure'
        dot_brkt = '[' + dots.replace('.', '].[') + ']'
        L = ord_singh_src_stop.sub('[CDWWork]', L)
        L = L.replace(underscores, dot_brkt)
    L = vinci.sub('[CDWWork]', L)
    L = ord_dflt.sub('[MyDB].[MySchema]', L)
    print(L + comment)
