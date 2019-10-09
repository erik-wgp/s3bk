#!/bin/bash

. /data/sysadm/_helpers.sh
. /data/code/s3bk/s3bk-upload-dir-vars.sh

### INCREMENTAL NOT TESTED OR FULLY IMPLEMENTED

INCREMENTAL=0

if [ "$1" == "--single-links-only" ]; then
   INCREMENTAL=1
   shift
fi


SRCDIR=$1
BACKUP_TYPE=$2

if [ "$SRCDIR" = "" ] || [ ! -d "$SRCDIR" ]; then
   echo "invalid src dir '$SRCDIR'" >&2
   exit 1
fi

if [ "$BACKUP_TYPE" != "" ]; then
	BACKUP_TYPE="--backup-type $BACKUP_TYPE"
fi

BKDIR=`basename $SRCDIR`
cd $SRCDIR/.. || error_exit "failed to chdir to $SRCDIR/.."

ADDL_TAR_ARGS=""
if [ -f .s3bk-additional ]; then
   . .s3bk-additional
fi

if [[ $INCREMENTAL != 0 ]]; then

   OUTFILE="$S3BK_SCRATCH_DIR/${BKDIR}-inc.tar.xz"

   ### generate a full file list, and differential file list
   find $BKDIR -type f > $BKDIR/BK_FILE_LIST
   find $BKDIR -type f -links 1 > $BKDIR/BK_FILE_LIST.inc

   set -o pipefail
   tar cf - -X /data/code/s3bk/s3bk-upload-dir-excludes --exclude-tag=.nobk $ADDL_TAR_ARGS -T $BKDIR/BK_FILE_LIST.inc | xz -c -T 0 -2 > $OUTFILE
   TAR_RC=$?
   set +o pipefail
else

   OUTFILE="$S3BK_SCRATCH_DIR/${BKDIR}.tar.xz"
   set -o pipefail
   #echo tar cf - -X /data/code/s3bk/s3bk-upload-dir-excludes --exclude-tag=.nobk $ADDL_TAR_ARGS $BKDIR \| xz -c -T 0 -2 \> $OUTFILE
         tar cf - -X /data/code/s3bk/s3bk-upload-dir-excludes --exclude-tag=.nobk $ADDL_TAR_ARGS $BKDIR  | xz -c -T 0 -2  > $OUTFILE
   TAR_RC=$?
   set +o pipefail
fi

if [[ $TAR_RC != 0 ]]; then
   echo "tar of $BKDIR failed" >&2
   exit 0
fi

ls -lh $OUTFILE | awk '{print $9" ("$5")"}'
/data/code/s3bk/s3bk-auto.rb $OUTFILE $BACKUP_TYPE

if [[ $? == 0 ]]; then
   mv $BKDIR $BKDIR-uploaded
fi

rm -f $OUTFILE
