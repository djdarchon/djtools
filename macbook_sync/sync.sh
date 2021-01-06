#-------------------------
# Author: Jaden Darchon
# Description:
#   Retrieves entire contents of macbook's DJ library and populates local
# directory structures as appropriate. That's it.
#



#-- USER VARIABLES: CHANGE THESE AS NEEDED --#
MACBOOK_USER=jadendarchon
MACBOOK_HOSTNAME=jadens-Macbook-Pro.local
MACBOOK_LIBRARY="DJ/library"
MACBOOK_SERATO="Music/_Serato_"



#-- CONSTANTS: DO NOT CHANGE --#
MACBOOK_CONN=${MACBOOK_USER}@${MACBOOK_HOSTNAME}:/Users/${MACBOOK_USER}
INCREMENTAL_DIR=/home/
declare -a sync_targets=("${MACBOOK_LIBRARY}" "${MACBOOK_SERATO}")



echo "Creating initial directory structure..."
[ ! -d "full" ] && mkdir full
[ ! -d "incremental" ] && mkdir incremental



echo "Synchronizing Macbook..."

# Commandline arguments
incremental=0
if [ "$#" == "1" ]; then
	if [ "${1}" == "-i" ]; then
		incremental=1
	fi
fi

# Incremental Mode:
#   If enabled, use the "incremental" directory. This saves on copy time as it
# uses existing files w/ rsync. Otherwise, we're creating a deep copy.
if [ ${incremental} == "1" ]; then
	echo "Incremental Mode: ON"
	SNAPSHOT_DIR=incremental
	echo "Using existing directory: ${SNAPSHOT_DIR}"
# Full Mode:
#   Deep copy of entire library and _Serato_ database.
else
	timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
	SNAPSHOT_DIR=full/${timestamp}
	echo "Incremental Mode: OFF"
	echo "Creating snapshot: ${SNAPSHOT_DIR}"
	mkdir ${SNAPSHOT_DIR}
fi

# "Caffeinate" the Mac... could go for a coffee myself!
echo "Caffeinating the Mac"
ssh ${MACBOOK_USER}@${MACBOOK_HOSTNAME} "caffeinate -s" &

# Recursively shadow everything under the remote conn to the snapshot dir
for target in "${sync_targets[@]}"; do
	echo "Synchronizing: ${target} ..."
	rsync -ar --progress ${MACBOOK_CONN}/${target} ${SNAPSHOT_DIR}
	echo "Done!"
done

echo "Decaffeinating the Mac"
ssh ${MACBOOK_USER}@${MACBOOK_HOSTNAME} "killall -9 caffeinate"

echo "Success!"
