function _aws-cget_backup_restoreJobs
  function cgrep 
    grep --line-buffered --color=always -P "$argv"
  end

  argparse --name='aws-cget backup restoreJobs' 's/state=' 'id=' 'since=' -- $argv
  set -l aws_args 
  if set -ql _flag_state
    set -a aws_args --by-state=$_flag_state
  end
  if set -ql _flag_since
    set -a aws_args --by-created-after="$(date -Is -d "$_flag_since")"
  end
  aws backup list-restore-jobs $aws_args | \
    jq -r '.RestoreJobs[] | @text "\(.RestoreJobId) \(.Status) \(.ResourceType):\((.CreatedResourceArn? | split(":")? | .[-1]) // null) \(.PercentDone)"' | \
    column -t | \
    GREP_COLORS='ms=01;34:ne=1' cgrep '(\s(PENDING|CREATED|RUNNING)\s)|$' | \
    GREP_COLORS='ms=01;32:ne=1' cgrep '(\s(COMPLETED)\s)|$'| \
    GREP_COLORS='ms=01;31:ne=1' cgrep '(\s(ABORTED|FAILED|EXPIRED)\s)|$' | \
    GREP_COLORS='ms=01;33:ne=1' cgrep '(\s(ABORTING)\s)|$'
end
