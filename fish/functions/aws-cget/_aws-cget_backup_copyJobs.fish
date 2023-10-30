function _aws-cget_backup_copyJobs
  function cgrep 
    grep --line-buffered --color=always -P "$argv"
  end

  argparse --name='aws-cget backup copyJobs' 's/state=' 'id=' 'since=' -- $argv
  set -l aws_args 
  if set -ql _flag_state
    set -a aws_args --by-state=$_flag_state
  end
  if set -ql _flag_since
    set -a aws_args --by-created-after="$(date -Is -d "$_flag_since")"
  end
  aws backup list-copy-jobs $aws_args | \
    jq -r '.CopyJobs[] | @text "\(.CopyJobId) \(.State) \(.ResourceType):\(.ResourceArn | split(":") | .[-1]) \(.DestinationBackupVaultArn | split(":")[3]) \(.DestinationBackupVaultArn | split(":")[4]) \(.DestinationBackupVaultArn | split(":")[6]) \(.CreationDate | split(".")[0])"' | \
    column -t | \
    GREP_COLORS='ms=01;34:ne=1' cgrep '(\s(PENDING|CREATED|RUNNING)\s)|$' | \
    GREP_COLORS='ms=01;32:ne=1' cgrep '(\s(COMPLETED)\s)|$'| \
    GREP_COLORS='ms=01;31:ne=1' cgrep '(\s(ABORTED|FAILED|EXPIRED)\s)|$' | \
    GREP_COLORS='ms=01;33:ne=1' cgrep '(\s(ABORTING)\s)|$'
end
