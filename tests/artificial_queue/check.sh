batch=1
msj=6

while [[ $(ls | wc -l) -lt $msj ]] ; do
    echo "batch $batch"
    echo "baluga" > "test-$batch.txt"
    sleep 5s

    batch=$(($batch + 1))
done