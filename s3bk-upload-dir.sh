#!/bin/bash

. /data/sysadm/_helpers.sh
. /data/code/s3bk/s3bk-upload-dir-vars.sh

INCREMENTAL=0

if [ "$1" == "--single-links-only" ]; then
   INCREMENTAL=1
   shift
fi


SRCDIR=$1
BACKUP_TYPE=$2

if [ "$BACKUP_TYPE" != "" ]; then
	BACKUP_TYPE="--backup-type $BACKUP_TYPE"
fi

BKDIR=`basename $SRCDIR`
cd $SRCDIR/.. || error_exit "failed to chdir to $SRCDIR/.."

if [[ $INCREMENTAL != 0 ]]; then

   OUTFILE="$S3BK_SCRATCH_DIR/${BKDIR}-inc.tar.xz"

   ### generate a full file list, and differential file list
   find $BKDIR -type f > $BKDIR/BK_FILE_LIST
   find $BKDIR -type f -links 1 > $BKDIR/BK_FILE_LIST.inc

   set -o pipefail
   tar cf - -X /data/code/s3bk/s3bk-upload-dir-excludes --exclude-tag=.nobk -T $BKDIR/BK_FILE_LIST.inc | xz -c -T 0 -2 > $OUTFILE
   TAR_RC=$?
   set +o pipefail
else

   OUTFILE="$S3BK_SCRATCH_DIR/${BKDIR}.tar.xz"
   set -o pipefail
   tar cf - -X /data/code/s3bk/s3bk-upload-dir-excludes --exclude-tag=.nobk $BKDIR | xz -c -T 0 -2 > $OUTFILE
   TAR_RC=$?
   set +o pipefail
fi

if [[ $TAR_RC != 0 ]]; then
   echo "tar of $BKDIR failed" >&2
   exit 0
fi

echo tar rc was $TAR_RC

ls -lh $OUTFILE
/data/code/s3bk/s3bk-auto.rb $OUTFILE $BACKUP_TYPE

if [[ $? == 0 ]]; then
   mv $BKDIR $BKDIR-uploaded
fi

rm -f $OUTFILE
