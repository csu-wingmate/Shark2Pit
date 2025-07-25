 1 #!/usr/bin/python3
  2
  3 import sys
  4 import time
  5 import os
  6
  7 edge_cnt=0
  8 out_file=sys.argv[2]
  9
 10 if os.path.exists(out_file):
 11     out_file=out_file+"_dup"
 12
 13 with open(out_file, "w") as f:
 14     f.close()
 15
 16 st = int(time.time())
 17 while True:
 18     with open(sys.argv[1], 'rb') as f:
 19         cur=int.from_bytes(f.read(4), "little")
 20         f.close()
 21     if edge_cnt<cur:
 22         edge_cnt=cur
 23         with open(out_file, "a") as f:
 24             f.write("{}, {}\n".format(int(time.time()) - st, edge_cnt))
 25             f.close()
 26             print("edge_cnt: {}".format(edge_cnt))
 27     time.sleep(1)