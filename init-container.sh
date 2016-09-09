#/bin/bash
firstLine=$(head -n 1 slaves)
echo $firstLine
docker run -h ${firstLine} --name ${firstLine} -ti jackyoh/encosystem:0.0.1 /bin/bash
