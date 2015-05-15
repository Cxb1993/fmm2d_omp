

NSOURCE=100000
#NSOURCE=1000000
OUTDIR="test/output"
NLOOP=2
#echo $NSOURCE
cd ..

#for P2T in 1 10 20
#  for M2M in 1 10 20
#    for M2L in 1 10 20
#      for P2M in 1 10 20

for CHUNK in 1 5 10 
do
for ((COUNT=1; COUNT<=$NLOOP; COUNT++ ))
do
#  echo $CHUNK
  cmd="./examples/int2 $NSOURCE $CHUNKSIZE $CHUNKSIZE $CHUNKSIZE $CHUNKSIZE"
  $cmd
  cmd="cp fort.13 $OUTDIR/output_${CHUNK}_${COUNT}"
  $cmd
#  echo $cmd
done
done
