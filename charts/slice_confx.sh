#!/bin/bash


nrfci=10
amfci=10
supfc1i=10
supfc2i=40

nrfc=10
amfc=10
supfc1=10
supfc2=40
gnbsimc=10

nousers=$1;
#mI=eno1np0
#mI=antrea-gw0
#mI=$2;


helm install mysql charts/mysql/ -n oai
kubectl wait --for=condition=available --timeout=200s deployment/mysql -n oai

mysqlIP=$(kubectl get pods -n oai -o wide| grep mysql | awk '{print $6}');


for ((nrf=1;nrf<=1;nrf++))
do
	#----------------------------------NRF Deployment----------------------------------------------------------
	sed -i "/name: oai-nrf/c\name: oai-nrf$nrfc " charts/oai-nrf/Chart.yaml
	sed -i "/oai-nrf-sa/c\  name: \"oai-nrf-sa$nrfc\"" charts/oai-nrf/values.yaml
	sed -i "/nrfIpNg/c\  nrfIpNg: \"10.100.11.$nrfc\"" charts/oai-nrf/values.yaml
	#sed -i "/master/c\      \"master\": \"$mI\"," charts/oai-nrf/templates/multus.yaml
	helm install nrf$nrfc charts/oai-nrf/ -n oai
	kubectl wait --for=condition=available --timeout=200s deployment/oai-nrf$nrfc -n oai

	for ((amf=1;amf<=1;amf++))
	do
		#----------------------------------AMF Deployment----------------------------------------------------------
		sed -i "/mySqlServer/c\  mySqlServer: \"$mysqlIP\"" charts/oai-amf/values.yaml
		sed -i "/name: oai-amf/c\name: oai-amf$amfc " charts/oai-amf/Chart.yaml
		sed -i "/oai-amf-sa/c\  name: \"oai-amf-sa$amfc\"" charts/oai-amf/values.yaml
		sed -i "/ngapIPadd/c\  ngapIPadd: \"10.100.12.$amfc\"" charts/oai-amf/values.yaml	
		sed -i "/nrfIpv4Addr/c\  nrfIpv4Addr: \"10.100.11.$nrfc\"" charts/oai-amf/values.yaml	
		sed -i "/smfIpv4Addr0/c\  smfIpv4Addr0: \"10.100.13.$supfc1\"" charts/oai-amf/values.yaml
		sed -i "/smfIpv4Addr1/c\  smfIpv4Addr1: \"10.100.13.$supfc2\"" charts/oai-amf/values.yaml
		#sed -i "/master/c\      \"master\": \"$mI\"," charts/oai-amf/templates/multus.yaml

		helm install amf$amfc charts/oai-amf/ -n oai
		kubectl wait --for=condition=available --timeout=200s deployment/oai-amf$amfc -n oai
		amfpod=$(kubectl get pods -n oai  | grep amf$amfc | awk '{print $1}')
		amfnet1IP=$(kubectl exec -n oai $amfpod -c amf -- ifconfig | grep "inet 10.100" | awk '{print $2}')
		#kubectl exec -n oai $amfpod -c amf -- ip route del default
		#kubectl exec -n oai $amfpod -c amf -- ip route add default via 169.254.1.1
		#kubectl exec -n oai $amfpod -c amf -- ip route del 10.100.0.0/16 via 0.0.0.0
		#kubectl exec -n oai $amfpod -c amf -- ip route add 10.100.0.0/16 via $amfnet1IP
	        #kubectl exec -n oai $amfpod -c amf -- ping -c 4 $mysqlIP

		#----------------------------------SMF Deployment----------------------------------------------------------
		sed -i "/name: oai-smf/c\name: oai-smf$supfc1 " charts/oai-smf/Chart.yaml
		sed -i "/oai-smf-sa/c\  name: \"oai-smf-sa$supfc1\"" charts/oai-smf/values.yaml
		sed -i "/n4IPadd/c\  n4IPadd: \"10.100.13.$supfc1\"" charts/oai-smf/values.yaml
		sed -i "/amfIpv4Address/c\  amfIpv4Address: \"10.100.12.$amfc\"" charts/oai-smf/values.yaml
		sed -i "/nrfIpv4Address/c\  nrfIpv4Address: \"10.100.11.$nrfc\"" charts/oai-smf/values.yaml
		sed -i "/upfIpv4Address/c\  upfIpv4Address: \"10.100.14.$supfc1\"" charts/oai-smf/values.yaml
		#sed -i "/master/c\      \"master\": \"$mI\"," charts/oai-smf/templates/multus.yaml
		helm install smf$supfc1 charts/oai-smf/ -n oai
		kubectl wait --for=condition=available --timeout=200s deployment/oai-smf$supfc1 -n oai

		#----------------------------------UPF Deployment----------------------------------------------------------
		sed -i "/name: oai-spgwu-tiny/c\name: oai-spgwu-tiny$supfc1 " charts/oai-spgwu-tiny/Chart.yaml
		sed -i "/oai-spgwu-tiny-sa/c\  name: \"oai-spgwu-tiny-sa$supfc1\"" charts/oai-spgwu-tiny/values.yaml
		sed -i "/sgwS1uIp/c\  sgwS1uIp: \"10.100.14.$supfc1\"" charts/oai-spgwu-tiny/values.yaml
		sed -i "/sgwSxIp/c\  sgwSxIp: \"10.100.15.$supfc1\" #net2 IP address for UPF" charts/oai-spgwu-tiny/values.yaml
		sed -i "/spgwc0IpAdd/c\  spgwc0IpAdd: \"10.100.13.$supfc1\" #SMF IP address" charts/oai-spgwu-tiny/values.yaml
		sed -i "/nrfIpv4Add/c\  nrfIpv4Add: \"10.100.11.$nrfc\" #NRF IP address" charts/oai-spgwu-tiny/values.yaml
		#sed -i "/master/c\      \"master\": \"$mI\"," charts/oai-spgwu/templates/multus.yaml
		helm install upf$supfc1 charts/oai-spgwu-tiny/ -n oai
		kubectl wait --for=condition=available --timeout=200s deployment/oai-spgwu-tiny$supfc1 -n oai

		for ((sim=1;sim<=nousers;sim++))
		do

			sed -i "/name/c\name: oai-gnbsim$gnbsimc" charts/oai-gnbsim/Chart.yaml
			sed -i "/ngapIPadd/c\  ngapIPadd: \"10.100.16.$gnbsimc\"" charts/oai-gnbsim/values.yaml
			sed -i "/gtpIPadd/c\  gtpIPadd: \"10.100.17.$gnbsimc\"" charts/oai-gnbsim/values.yaml
			sed -i "/gtpulocaladdr/c\  gtpulocaladdr: \"10.100.16.$gnbsimc\"" charts/oai-gnbsim/values.yaml
			sed -i "/ngappeeraddr/c\  ngappeeraddr: \"10.100.12.$amfc\"" charts/oai-gnbsim/values.yaml
			sed -i "/gnbid/c\  gnbid: \"$gnbsimc\"" charts/oai-gnbsim/values.yaml
			sed -i "/msin/c\  msin: \"10000000$gnbsimc\"" charts/oai-gnbsim/values.yaml
			sed -i "16s/.*/  name: \"oai-gnbsim-sa$gnbsimc\"/" charts/oai-gnbsim/values.yaml
			sed -i "/key/c\  key: \"0C1A34601D4F07677303652C046250$gnbsimc\"" charts/oai-gnbsim/values.yaml
			#sed -i "/master/c\      \"master\": \"$mI\"," charts/oai-gnbsim/templates/multus.yaml

			helm install gnbsim$gnbsimc charts/oai-gnbsim/ -n oai 
			kubectl wait --for=condition=available --timeout=200s deployment/oai-gnbsim$gnbsimc -n oai	

			sleep 30
			gnbsimpod=$(kubectl get pods -n oai  | grep oai-gnbsim$gnbsimc | awk '{print $1}')
			((gnbsimIP=$sim+1))
			echo $gnbsimIP
			kubectl exec -it -n oai $gnbsimpod -- ip route replace 10.100.20.12 via 0.0.0.0 dev net1 src 12.1.1.$gnbsimIP
			((gnbsimc+=1))
		done
		((supfc1+=1))
		((supfc2+=1))
		((amfc+=1))
	done
	((nrfc+=1))
done

kubectl apply -k charts/oai-dnn/
kubectl wait --for=condition=available --timeout=200s deployment/oai-dnn11 -n oai
dnnpod=$(kubectl get pods -n oai  | grep oai-dnn | awk '{print $1}')
kubectl exec -it -n oai $dnnpod -- iptables -t nat -A POSTROUTING -o net1 -j MASQUERADE
kubectl exec -it -n oai $dnnpod -- ip route add 12.1.0.0/16 via 10.100.14.10 dev net1
kubectl exec -it -n oai $dnnpod -- ping -c 2 12.1.1.2


