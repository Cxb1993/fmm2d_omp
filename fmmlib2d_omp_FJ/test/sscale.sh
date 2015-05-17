

NSOURCE=100000
#NSOURCE=1000000
OUTDIR="test/output"
NLOOP=2
CHUNKSIZE=100
#echo $NSOURCE
cd ..
mkdir $OUTDIR

#for P2T in 1 10 20
#  for M2M in 1 10 20
#    for M2L in 1 10 20
#      for P2M in 1 10 20

for NCORES in 1 2 4 8 16 32 60 
do
for ((COUNT=1; COUNT<=$NLOOP; COUNT++ ))
do
  echo $NCORES
  cmd="./examples/int2 $NSOURCE $CHUNKSIZE $CHUNKSIZE $CHUNKSIZE $CHUNKSIZE"
#  $cmd
  cmd="cp fort.13 $OUTDIR/output_${NCORES}_${COUNT}"
  $cmd
#  echo $cmd
done
done
