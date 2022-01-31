#!/bin/bash

helm delete mysql -n oai
helm delete nrf10 -n oai
helm delete amf10 -n oai
helm delete smf10 -n oai
helm delete upf10 -n oai
kubectl delete deployment -n oai oai-dnn11

for ((count=10;count<$1+10;count++))
do
        helm delete gnbsim$count -n oai
done
