import re, sys
# Resolve every conflict hunk in the given files by keeping both sides, ours first.
for p in sys.argv[1:]:
    s = open(p).read()
    s = re.sub(r"<<<<<<< [^\n]*\n(.*?)=======\n(.*?)>>>>>>> [^\n]*\n",
               lambda m: m.group(1) + ("\n" if not m.group(1).endswith("\n\n") else "") + m.group(2), s, flags=re.S)
    open(p, 'w').write(s)
