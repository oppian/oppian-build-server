#!/bin/bash -ex

# packages: xfsprogs

# inputs: EBS_DEVICE2, EBS_MOUNT2, USE_LOCAL_STORAGE2

#waiting for a device to exist helper
# Param 1: device name
# Param 2: timeout (seconds)
# return 0 (success) 1 (failure)
wait_for_device ()
{
device=$1
to=$2
echo "Waiting for device..."
for i in `seq 1 $to`;
 do
 ls $device >/dev/null 2>&1
 if [ "$?" == "0" ]; then
   return 0
 fi
 echo -n "." && sleep 1
done
return 1
}


# Format an EBS volume if it's not empty (i.e., the first 1MB of disk is not all 0's)
# Param 1: device name
# Param 2: filesystem type (i.e., xfs, ext3...)
# returns 0

format_if_empty ()
{
device=$1
fs_type=$2
echo "Formatting EBS volume if empty..."
# Create a good tmp place for the test files.
# folder=/tmp/EBS-`date +%j%H%M%S`
folder=/tmp/EBS-`date +%j%H%M%S%N`

mkdir -p $folder

# Read a 1M sample of the disk and make a zeroed file for the cmp command.
dd if=/dev/zero      of=$folder/zeros count=1 bs=1M
dd if=$device        of=$folder/EBS   count=1 bs=1M

# Report to the logs details.
# This is a MD5 checksum of the files to watch for indicators of data in the audit.
ls -lsag $folder
md5sum $folder/*

#
# Test for Bits that are all zero,  then do the format command.
#
if cmp $folder/EBS  $folder/zeros; then
 echo "The volume is zeros it is safe to format the Volume"
 logger -t RightScale "Volume was zero so we formatted it with xfs"
#
# This extra echo y is due to the need to reply yes to a question
# asked about the whole disk as one partition.
#
 echo y | mkfs.$fs_type $device

else
 echo "The EBS Volume has bits,  it may be formatted,  skip it."
 logger -t RightScale "Volume came formatted,  or has data, skipping format"
fi
rm -rf $folder
return 0
}
#############################
attach_device ()
{
ebs_device=$1
datastore_path=$2
echo "Waiting for EBS device to attach..."
# Wait max of 300 secs for the EBS device to attach
wait_for_device $ebs_device 300
# Create (if not there) and change the datastore directory
if [ $? == 0 ]; then
 echo "Device attachment completed!"
else
 echo "Device attachment didn't complete within the allowed period....aborting."
 echo "Make sure EBS_DEVICE2 is set correctly and the EBS volume is attached on boot"
 echo "Using Local Storage instead of EBS"
 echo
 exit 1
fi
format_if_empty $ebs_device xfs
mkdir -p $datastore_path
mount -t xfs $ebs_device $datastore_path
if [ $? != 0 ]; then
  echo "Error mounting EBS volume...(is the volume formatted?)...aborting."
  echo "Using Local Storage instead of EBS"
  exit 1
fi
echo "done"
}

mkdir -p $EBS_MOUNT2

if [ "$USE_LOCAL_STORAGE2" = "NO" ]; then
  attach_device $EBS_DEVICE2 $EBS_MOUNT2
fi

exit 0