#-------------------------
# Author: Jaden Darchon
# Description:
#   Retrieves entire contents of macbook's DJ library and populates local
# directory structures as appropriate. That's it.
#
echo "Synchronizing Macbook..."

# Commandline arguments
incremental=0
if [ "$#" == "1" ]; then
	if [ "${1}" == "-i" ]; then
		incremental=1
	fi
fi

# Constants
REMOTE_USER=jadendarchon@192.168.0.228
REMOTE_CONN=${REMOTE_USER}:/Users/jadendarchon
INCREMENTAL_DIR=/mnt/fileroot/work/macbook/incremental
declare -a sync_targets=("DJ/library" "Music/_Serato_")

# Incremental Mode:
#   If enabled, use the "incremental" directory. This saves on copy time as it
# uses existing files w/ rsync. Otherwise, we're creating a deep copy.
if [ ${incremental} == "1" ]; then
	echo "Incremental Mode: ON"
	SNAPSHOT_DIR=/mnt/fileroot/work/macbook/incremental
	echo "Using existing directory: ${SNAPSHOT_DIR}"
else
	timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
	SNAPSHOT_DIR=/mnt/fileroot/work/macbook/${timestamp}
	echo "Incremental Mode: OFF"
	echo "Creating snapshot: ${SNAPSHOT_DIR}"
	#cp -pr ${INCREMENTAL_DIR} ${SNAPSHOT_DIR}
	mkdir ${SNAPSHOT_DIR}
fi

# "Caffeinate" the Mac..
echo "Caffeinating the Mac"
ssh ${REMOTE_USER} "caffeinate -s" &

# Recursively shadow everything under the remote conn to the snapshot dir
for target in "${sync_targets[@]}"; do
	echo "Synchronizing: ${target} ..."
	rsync -ar --progress ${REMOTE_CONN}/${target} ${SNAPSHOT_DIR}
	echo "Done!"
done

echo "Decaffeinating the Mac"
ssh ${REMOTE_USER} "killall -9 caffeinate"

echo "Success!"
