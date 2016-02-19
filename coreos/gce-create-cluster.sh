#!/bin/bash

usage()
{
    cat << EOF
Create coreos instances on GCE and attach a disk where the binaries will be installed

Usage : $(basename $0) [-c <number of instances>] [-z <zone>] [-t <machine_type>] [-i <image_url>]
      -h | --help		: Show this message
      -c | --count		: Number of CoreOS instances to create
      -t | --machine-type	: GCE machine type
      -t | --image		: CoreOS image to use
               
               ex : 
               $(basename $0) -c 3
EOF
}

# Options parsing
while (($#)); do
    case "$1" in
        -h | --help)   usage;   exit 0;;
        -c | --count) COUNT=${2}; shift 2;;
        -z | --zone) ZONE=${2}; shift 2;;
        -t | --machine-type) TYPE=${2}; shift 2;;
        -i | --image) IMAGE=${2}; shift 2;;
        *)
            usage
            echo "ERROR : Unknown option"
            exit 3
        ;;
    esac
done

if [ -z ${COUNT} ]; then
    COUNT=1
fi
if [ -z ${IMAGE} ]; then
    IMAGE="https://www.googleapis.com/compute/v1/projects/coreos-cloud/global/images/coreos-stable-835-13-0-v20160218"
fi
if [ -z ${TYPE} ]; then
    TYPE="n1-standard-1"
fi

for n in $(seq 1 ${COUNT}); do
    if [ ! -z ${ZONE} ]; then
        echo "creating instances in zone ${ZONE}"
        gcloud -q compute disks create coreos-binaries-${n} --size 10GB --zone ${ZONE} && \
        gcloud -q compute instances create core${n} \
        --zone ${ZONE} \
        --image ${IMAGE} \
        --machine-type ${TYPE} \
        --metadata-from-file user-data="$(dirname $0)/cloud-config.yaml" \
        --disk name=coreos-binaries-${n},device-name=binaries 
    else
        gcloud -q compute disks create coreos-binaries-${n} --size 10GB && \
        gcloud -q compute instances create core${n} \
        --image ${IMAGE} \
        --machine-type ${TYPE} \
        --metadata-from-file user-data="$(dirname $0)/cloud-config.yaml" \
        --disk name=coreos-binaries-${n},device-name=binaries 
    fi
done
