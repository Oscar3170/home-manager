function _aws-cget_backup_jobs
  function cgrep 
    grep --line-buffered --color=always -P "$argv"
  end

  argparse --name='aws-cget backup jobs' 's/state=' 'id=' -- $argv
  set -l aws_args 
  if set -ql _flag_state
    set -a aws_args --by-state=$_flag_state
  end
  aws backup list-backup-jobs $aws_args | \
    jq -r '.BackupJobs[] | @text "\(.BackupJobId) \(.State) \(.ResourceType):\(.ResourceArn | split(":") | .[-1]) \(.PercentDone)%"' | \
    column -t | \
    GREP_COLORS='ms=01;34:ne=1' cgrep '(\s(PENDING|CREATED|RUNNING)\s)|$' | \
    GREP_COLORS='ms=01;32:ne=1' cgrep '(\s(COMPLETED)\s)|$'| \
    GREP_COLORS='ms=01;31:ne=1' cgrep '(\s(ABORTED|FAILED|EXPIRED)\s)|$' | \
    GREP_COLORS='ms=01;33:ne=1' cgrep '(\s(ABORTING)\s)|$'
end
