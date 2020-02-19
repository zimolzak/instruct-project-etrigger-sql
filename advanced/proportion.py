files = ['Fobt.sql', 'HCC.sql', 'IDA.sql', 'Lung.sql']
search_str = 'Singh'

for f in files:
    lines = open(f).read().splitlines()
    numer = 0
    denom = len(lines)
    for L in lines:
        if search_str in L:
            numer += 1
    proportion_str = str(round(numer / float(denom), 3))
    print('%d / %d\tlines in %s\tcontain "%s", = %s.' % \
              (numer, denom, f, search_str, proportion_str))
