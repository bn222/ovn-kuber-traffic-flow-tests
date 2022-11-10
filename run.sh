#!/bin/bash


set -x

OVN_KUBER_TRAFFIC_FLOW_TEST_REPO=https://github.com/wizhaoredhat/ovn-kuber-traffic-flow-tests
export FT_NAMESPACE="default"
export FT_REQ_SERVER_NODE=${HOSTNAME_BMH_NODE_1}
export FT_REQ_REMOTE_CLIENT_NODE=${HOSTNAME_BMH_NODE_2}
export FT_SRIOV_NODE_LABEL="feature.node.kubernetes.io/network-sriov.capable"
export SRIOV_RESOURCE_NAME="openshift.io/${NIC_RESOURCE_NAME}"
export TEST_IMAGE="quay.io/wizhao/ft-base-image:0.8-x86_64"
export TEST_FLOW_IPERF_CMD="iperf3"
export HWOL_FLOW_LEARNING_TIME="30"
export TRAFFIC_FLOW_TEST_IPERF_TIME="1800"
#export IPERF_CMD="taskset -c 5 iperf3"

echo
echo "VARIABLES for this script:"
echo "================================="
echo "KUBECONFIG                       =${KUBECONFIG}"
echo "OVN_KUBER_TRAFFIC_FLOW_TEST_REPO =${OVN_KUBER_TRAFFIC_FLOW_TEST_REPO}"
echo "HOSTNAME_BMH_NODE_1              =${HOSTNAME_BMH_NODE_1}"
echo "HOSTNAME_BMH_NODE_2              =${HOSTNAME_BMH_NODE_2}"
echo "FT_NAMESPACE                     =${FT_NAMESPACE}"
echo "FT_REQ_SERVER_NODE               =${FT_REQ_SERVER_NODE}"
echo "FT_REQ_REMOTE_CLIENT_NODE        =${FT_REQ_REMOTE_CLIENT_NODE}"
echo "FT_SRIOV_NODE_LABEL              =${FT_SRIOV_NODE_LABEL}"
echo "SRIOV_RESOURCE_NAME              =${SRIOV_RESOURCE_NAME}"
echo "================================="
echo

ipvalid() {
    # Set up local variables
    local ip=${1:-1.2.3.4}
    local IFS=.; local -a a=($ip)
    # Start with a regex format test
    [[ $ip =~ ^[0-9]+(\.[0-9]+){3}$ ]] || return 1
    # Test values of quads
    local quad
    for quad in {0..3}; do
        [[ "${a[$quad]}" -gt 255 ]] && return 1
    done
    return 0
}

set -e
set -x

./cleanup.sh
IPERF_CMD="${TEST_FLOW_IPERF_CMD}" ./launch.sh

# Check the IP address of the pod. This is assigned dynamically.
TMP_GET_PODS_STR=$(kubectl get pods -n ${FT_NAMESPACE} -o wide)
HTTP_SERVER_POD_NAME=${HTTP_SERVER_POD_NAME:-ft-http-server-pod-v4}
IPERF_SERVER_POD_NAME=${IPERF_SERVER_POD_NAME:-ft-iperf-server-pod-v4}


rm hwol-logs/summary.txt

retry=0
while : ; do
    sleep 5
    TMP_GET_PODS_STR=$(kubectl get pods -n ${FT_NAMESPACE} -o wide)
    HTTP_SERVER_POD_IP=$(echo "${TMP_GET_PODS_STR}" | grep $HTTP_SERVER_POD_NAME  | awk -F' ' '{print $6}')
    if ipvalid "${HTTP_SERVER_POD_IP}"; then
        echo "Success HTTP_SERVER_POD_IP=${HTTP_SERVER_POD_IP}"
        break
    elif [ "${retry}" -ge 60 ]; then
        echo "Max retry limit reached retry=${retry} IPERF_SERVER_POD_IP=${IPERF_SERVER_POD_IP}"
        break
    else
        echo "Retrying attempt retry=${retry} HTTP_SERVER_POD_IP=${HTTP_SERVER_POD_IP}"
        retry=$((retry+1))
    fi
done

retry=0
while : ; do
    sleep 5
    TMP_GET_PODS_STR=$(kubectl get pods -n ${FT_NAMESPACE} -o wide)
    IPERF_SERVER_POD_IP=$(echo "${TMP_GET_PODS_STR}" | grep $IPERF_SERVER_POD_NAME  | awk -F' ' '{print $6}')
    if ipvalid "${IPERF_SERVER_POD_IP}"; then
        echo "Success IPERF_SERVER_POD_IP=${IPERF_SERVER_POD_IP}"
        break
    elif [ "${retry}" -ge 60 ]; then
        echo "Max retry limit reached retry=${retry} IPERF_SERVER_POD_IP=${IPERF_SERVER_POD_IP}"
        break
    else
        echo "Retrying attempt retry=${retry} IPERF_SERVER_POD_IP=${IPERF_SERVER_POD_IP}"
        retry=$((retry+1))
    fi
done

# FT_NOTES disables the output of NOOP tests.
# FT_VARS displays the env variables.
# IPERF enables the use of IPERF.
#FT_NOTES=false FT_VARS=true IPERF=true IPERF_TIME=30 HWOL=true ./test.sh
if [[ "$TEST_FLOW_IPERF_CMD" == *"iperf3"* ]]; then
    TEST_CASE=1 FT_NOTES=false FT_VARS=true HWOL=true HWOL_IPERF_TIME=${TRAFFIC_FLOW_TEST_IPERF_TIME} ./test.sh
    TEST_CASE=5 FT_NOTES=false HWOL=true HWOL_IPERF_TIME=${TRAFFIC_FLOW_TEST_IPERF_TIME} ./test.sh
    TEST_CASE=6 FT_NOTES=false HWOL=true HWOL_IPERF_TIME=${TRAFFIC_FLOW_TEST_IPERF_TIME} ./test.sh
    TEST_CASE=3 FT_NOTES=false HWOL=true HWOL_IPERF_TIME=${TRAFFIC_FLOW_TEST_IPERF_TIME} ./test.sh
    TEST_CASE=4 FT_NOTES=false HWOL=true HWOL_IPERF_TIME=${TRAFFIC_FLOW_TEST_IPERF_TIME} ./test.sh
    TEST_CASE=9 FT_NOTES=false HWOL=true HWOL_IPERF_TIME=${TRAFFIC_FLOW_TEST_IPERF_TIME} ./test.sh
    TEST_CASE=10 FT_NOTES=false HWOL=true HWOL_IPERF_TIME=${TRAFFIC_FLOW_TEST_IPERF_TIME} ./test.sh
    TEST_CASE=11 FT_NOTES=false HWOL=true HWOL_IPERF_TIME=${TRAFFIC_FLOW_TEST_IPERF_TIME} ./test.sh
    TEST_CASE=12 FT_NOTES=false HWOL=true HWOL_IPERF_TIME=${TRAFFIC_FLOW_TEST_IPERF_TIME} ./test.sh
else
    IPERF_CMD="${TEST_FLOW_IPERF_CMD} -i 1" TEST_CASE=1 FT_NOTES=false FT_VARS=true HWOL=true HWOL_IPERF_TIME=${TRAFFIC_FLOW_TEST_IPERF_TIME} ./test.sh
    IPERF_CMD="${TEST_FLOW_IPERF_CMD} -i 1" TEST_CASE=5 FT_NOTES=false HWOL=true HWOL_IPERF_TIME=${TRAFFIC_FLOW_TEST_IPERF_TIME} ./test.sh
    IPERF_CMD="${TEST_FLOW_IPERF_CMD} -i 1" TEST_CASE=6 FT_NOTES=false HWOL=true HWOL_IPERF_TIME=${TRAFFIC_FLOW_TEST_IPERF_TIME} ./test.sh
    IPERF_CMD="${TEST_FLOW_IPERF_CMD} -i 1" TEST_CASE=3 FT_NOTES=false HWOL=true HWOL_IPERF_TIME=${TRAFFIC_FLOW_TEST_IPERF_TIME} ./test.sh
    IPERF_CMD="${TEST_FLOW_IPERF_CMD} -i 1" TEST_CASE=4 FT_NOTES=false HWOL=true HWOL_IPERF_TIME=${TRAFFIC_FLOW_TEST_IPERF_TIME} ./test.sh
    IPERF_CMD="${TEST_FLOW_IPERF_CMD} -i 1" TEST_CASE=9 FT_NOTES=false HWOL=true HWOL_IPERF_TIME=${TRAFFIC_FLOW_TEST_IPERF_TIME} ./test.sh
    IPERF_CMD="${TEST_FLOW_IPERF_CMD} -i 1" TEST_CASE=10 FT_NOTES=false HWOL=true HWOL_IPERF_TIME=${TRAFFIC_FLOW_TEST_IPERF_TIME} ./test.sh
    IPERF_CMD="${TEST_FLOW_IPERF_CMD} -i 1" TEST_CASE=11 FT_NOTES=false HWOL=true HWOL_IPERF_TIME=${TRAFFIC_FLOW_TEST_IPERF_TIME} ./test.sh
    IPERF_CMD="${TEST_FLOW_IPERF_CMD} -i 1" TEST_CASE=12 FT_NOTES=false HWOL=true HWOL_IPERF_TIME=${TRAFFIC_FLOW_TEST_IPERF_TIME} ./test.sh
fi

sleep 10

cat hwol-logs/summary.txt

# TODO store hwol-logs somewhere.

# TODO FIXME Temp Disable Cleanup to troubleshoot
#./cleanup.sh

