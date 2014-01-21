#! /bin/bash
cd $HOME/Report\ Results
for hhvm_build in hhvmbumpnocount hhvmbump hhvmnocount hhvmclean
do

	for requests in 200 400 600 800 1000 1200 1400 1600
	do
		for conc in 40 80 120 160 200 240 280 320 360 400
		do
			if [ "$conc" -gt "$requests" ]
			then
				continue
			fi

			$HOME/$hhvm_build/hphp/hhvm/hhvm -m s -p 8080 -vEval.Jit=True 2>/dev/null &
			echo "waiting for $hhvm_build to start" && sleep 2
			
			echo "running warmup request"	
			wget -O /dev/null -o /dev/null http://localhost:8080/benchmarks/center-of-mass.php 
			
			echo "running ab test: -n "$requests" -c "$conc
			OUTFILE=results/$hhvm_build"-n"$requests"-c"$conc
			ab -c $conc -n $requests -g $OUTFILE.gnuplot -e $OUTFILE.csv http://localhost:8080/benchmarks/center-of-mass.php > $OUTFILE.log
				
			echo "killing hhvm"
			killall -q hhvm  && sleep 2
		done
	done
done
