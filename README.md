
# S3BK

## Usage

```
# ./s3bk-upload-dir.sh /data/bks/server-sync-20190912
-rw-r--r-- 1 root root 2.9G Oct  2 12:59 /scratch/server-sync-20190912.tar.xz
uploaded /scratch/server-sync-20190912.tar.xz as short

# ./s3bk-auto.rb --rename-suffix .uploaded /data/bks/dbbk_myapp_prod_20190901.xz
uploaded dbbk_myapp_prod_20190901.xz as long

```


This is a set of tools to backup files and directories on a recurring basis to s3.  The result will be an S3 bucket with backups being retained at desired intervals, e.g. a monthly backup for 6 months, a weekly backup for 3 months, etc.  The S3 bucket lifecycle policy automatically handles the transition, and glacier can be used to greatly lower long term costs.

Out of the box, this code assumes:
- monthly backups kept for 6 months
- weekly backups kept for 3 months
- even day backups kept for 1 month
- daily backups kept for 2 weeks

The retentions can be modified easily inside the s3 lifecycle policy.  Some code modification would be required to divide the backups differently, for instance into every 3rd or 10th day, quarters, etc - see `S3bk.datestring_matches_interval` in `s3bk.rb`.

These scripts were conceived to be run on a central backup server with rsync file backups and database backups.  The backups are meant to survive a severe security event if configured properly (see CAVEATS).  It would be possible to adapt this to have servers back themselves up rather than centralizing.

The following assumes basic understanding of AWS command line tools, S3 and IAM configuration, etc.

## Prerequisites

- Files or folders to be archived, which must have a date string like "20180214" in their name for parsing.
- An S3 bucket with no public access
- An AWS IAM user with the following attached policy (update "your-bucket-name").  Note the access info.

```
{
   "Version": "2012-10-17",
   "Statement": [
       {
           "Effect": "Allow",
           "Action": [
               "s3:PutObject"
           ],
           "Resource": [
               "arn:aws:s3:::your-bucket-name/*",
           ]
       }
   ]
}
```

- The uploader access credentials in `~/.aws`.  They can be setup as a named profile, e.g. `[s3bk]`

- A lifecycle policy.  This can be done graphically in the AWS console under the "Management" pane for the bucket, or review the bucket policy in `sample-bucket-lifecycle-policy.json` and assign to your bucket (you'll need admin credentials):
```
AWS_PROFILE=admin aws s3api put-bucket-lifecycle-configuration \
                            --bucket your-bucket-name \
                            --lifecycle-configuration \
                            file:///path/to/sample-bucket-lifecycle-policy.json
```

- Setup ruby (2.6.4 currently) and gems (aws-sdk, activerecord awesome_print)

## Setup

- Copy `s3bk.yml.sample` as `s3bk.yml`, setup the bucket_name and bucket_path, and retentions to match the lifecycle policy

- For directory backups, copy `s3bk-upload-dir-vars.sh.sample` to `s3bk-upload-dir-vars.sh` and set a path for temporary files (which will be the size of the entire folder being backed up, compressed)

- Run `s3bk-show-placements-by-date.rb` to see how the code interprets the retention for nearby dates

- Give it a try:
```
/some/path/s3bk/s3bk-auto.rb --rename-suffix .uploaded dbbk_my_appproduction_20190927.xz
/some/path/s3bk/s3bk-upload-dir.sh /backup/dir/path/20190927
```


## CAVEATS - important
- The retention settings in s3bk.yml or for display/reference purposes and don't necessarily match the lifecycle.  In fact this code ultimately just uploads things to buckets.  Whether they are retained/transitioned/expired properly depends on the bucket lifecycle policy.  Check that carefully and review it at intervals.

- There are charges for premature deletion of objects from glacier or even infrequent access.  There may be bandwidth charges, or any number of other charges which the user should be familiar with before starting.  Test with small files and best sure you are happy with the setup before uploading large quantities of data.

- These scripts always append a random string to the uploaded file name so that an attacker can't overwrite the backups.  It is recommended that the server running these commands not have any access keys which would allow any listing or administrative privileges of the backup bucket.

- For best security create a separate AWS account with very tight access (ie, offline storage of authentication), so that even in the event of a catastrophic security event, there are still backups.

- This code doesn't support incremental backups directly, although if the source files it was backing up were differentials it would be agnostic
-
