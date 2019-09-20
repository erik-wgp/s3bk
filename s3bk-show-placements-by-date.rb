#!/bin/env ruby

require File.dirname(__FILE__) + '/s3bk.rb'

### build a datastructure to display whitespace before the backup type, to make it easier to
### visually view the distribution

tab_map = {}
sorted_bktypes = $s3bk_config["bk_map"].sort { |a,b| a[1]["retention"] <=> b[1]["retention"] }

i = 0
sorted_bktypes.each do |bktype|
   tab_map[bktype[0]] = " " * i
   i += 8
end

( -32..32 ).each do |n|
   backup_type = s3bk_determine_backup_type_from_filename("file_" + (Time.now + n.day).strftime("%Y%m%d"))
   printf("%-12s %s %-20s\n", (Time.now + n.day).strftime("%Y-%m-%d"), tab_map[backup_type], backup_type)
   n += 1
end

