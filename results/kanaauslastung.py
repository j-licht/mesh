#!/usr/bin/python3
import sys
import matplotlib.pyplot as plt
import numpy as np

fh = open(sys.argv[1])
control = []
payload = []

secounds = 0
start_time = -1.0
end_time = -1.0
used_control = 0
used_payload = 0
for line in fh.readlines():
    columns = line.split()
#    print(line)
    if columns[0] == 'T':
        #trannsmission from before ended, write back
        if start_time != -1.0:
 #           print(end_time)
  #          print('diff' + str(end_time - start_time))
            if columns[4] == 'WlanAck':
                used_payload += (end_time - start_time)
            else:
                used_control += (end_time - start_time)
        start_time = float(columns[7])
   #     print('start_time' + str(start_time))

        if start_time > secounds + 1:
            control.append(used_control)
            payload.append(used_payload)
            used_control = 0
            used_payload = 0
            secounds += 1
    #        exit(0)
  #  print(columns[14])
    if columns[0] == 'R' and float(columns[14]) > end_time:
        end_time = float(columns[14])
     #   print('end_time' + str(end_time))

print('control' + str(np.mean(control)))
print('payload' + str(np.mean(payload)))
plt.plot(control, label='used control')
plt.plot(payload, label='used payload')
plt.legend()
plt.show()
