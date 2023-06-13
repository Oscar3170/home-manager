function aws-cget
  function cgrep 
    grep --line-buffered --color=always -P $argv
  end
  aws rds describe-db-instances $argv | \
    jq -r '.DBInstances[] | @text "\(.DBInstanceIdentifier)  \(.DBInstanceStatus) \(.Engine)  \(.DBInstanceClass)"' | \
    column -t | \
    GREP_COLORS='ms=01;34:ne=1' cgrep '\s(creating|backing-up)\s|$' | \
    GREP_COLORS='ms=01;33:ne=1' cgrep '\s(stopped|stopping)\s|$' | \
    GREP_COLORS='ms=01;32:ne=1' cgrep '\s(available)\s|$'| \
    GREP_COLORS='ms=01;31:ne=1' cgrep '\s(deleting)\s|$'
end
