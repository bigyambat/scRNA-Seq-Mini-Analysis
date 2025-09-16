import vcf as vcf
import cProfile
import timeit
import pstats
import sys
import os

def parse_1kg():
    in_vcf = vcf.Reader(filename='vcf/test/1kg.vcf.gz')
    with open(os.devnull, "w") as fh:
        out_vcf = vcf.Writer(fh, template=in_vcf)
        for line in in_vcf:
            out_vcf.write_record(line)

if len(sys.argv) == 1:
    sys.argv.append(None)

if sys.argv[1] == 'profile':
    cProfile.run('parse_1kg()', '1kg.prof')
    p = pstats.Stats('1kg.prof')
    p.strip_dirs().sort_stats('time').print_stats()

elif sys.argv[1] == 'time':
    n = 1
    t = timeit.timeit('parse_1kg()',  "from __main__ import parse_1kg", number=n)
    print(t/n)

elif sys.argv[1] == 'stat':
    import statprof
    statprof.start()
    try:
        parse_1kg()
    finally:
        statprof.stop()
        statprof.display()
elif sys.argv[1] == 'run':
    parse_1kg()
else:
    print('prof.py profile/time')
