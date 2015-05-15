import glob
import numpy as np
fw=open("result.txt",'a')

size=[]
time=[]

for name in glob.glob('./output/output*'):
    pre='./output/output_'
    str=name[len(pre):len(name)]
    list=str.split('_')
    size.append(list[0])
    #fw.write(list[0]+' '+list[1]+' ')
    fr=open(name,'r')
    for line in fr:
        if 'time in fmm main' in line:
            #fw.write(next(fr))
            time.append(float(next(fr)))
fr.close()

while len(size) > 0:
    index=[0]
    sum=time[0]
    for i in range(1,len(size)):
        if size[i]==size[0]:
           index.append(i)
           sum+=time[i]
    t=sum/len(index)
    print('%s\t%g\n'%(size[0],sum/len(index)),file=fw)
    size=np.delete(size,index,0)
    time=np.delete(time,index,0)

fw.close()