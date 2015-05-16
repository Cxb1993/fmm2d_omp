import glob
#import numpy as np
fw=open("result.txt",'w')

size=[]
time=[]
num=[]

for name in glob.glob('./output/output*'):
    pre='./output/output_'
    str=name[len(pre):len(name)]
    list=str.split('_')
    fr=open(name,'r')
    for line in fr:
        if 'time in fmm main' in line:
            t=float(next(fr))
    fr.close()
    j=0
    while j<len(size):
        if list[0]==size[j]:
            num[j]+=1
            time[j]+=t
            break
        j+=1
    if j==len(size):
        size.append(list[0])
        time.append(t)
        num.append(1)

for i in range(len(size)):
    print('%s\t%f\n'%(size[i],time[i]/num[i]),file=fw)

fw.close()