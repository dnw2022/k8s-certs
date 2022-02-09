# https://cloud.google.com/sdk/gcloud/reference/container/clusters/create
# gcloud container get-server-config (list available options)
GC_CLUSTERNAME=cluster-dnw-gcloud \
GC_ZONE=europe-central2-a \
GC_IMAGE_TYPE=COS_CONTAINERD \
GC_MACHINE_TYPE=e2-micro \
GC_DISKTYPE=pd-standard \
GC_DISKSIZE=20

gcloud container clusters create $GC_CLUSTERNAME \
  --zone $GC_ZONE \
  --image-type $GC_IMAGE_TYPE \
  --machine-type $GC_MACHINE_TYPE \
  --disk-type $GC_DISKTYPE \
  --disk-size $GC_DISKSIZE \

  