function glab-var-edit
  argparse --min-args 1 'f/format=' 'm/masked' 'p/protected' 'e/expandable' 't/type=' 's/scope=' -- $argv 
  or return

  set -f var_name $argv[1]

  set -f repo_name (string replace -a '/' '_' (glab repo view -F json | jq -r '.path_with_namespace'))
  or return

  set -x TMP_FILE "/tmp/glab-var-$repo_name-$var_name"

  if set -ql _flag_scope
    set -f scope "$_flag_scope"
    set -x TMP_FILE "$TMP_FILE-$scope"
  else
    set -f scope "*"
  end

  if set -ql _flag_type
    set -f type "$_flag_type"
  else
    set -f type "env_var"
  end


  if set -ql _flag_format
    set -x TMP_FILE "$TMP_FILE.$_flag_format"
  end

  function _clean_up
    rm -f $TMP_FILE $TMP_FILE.before
  end

  glab variable get --scope $scope $var_name > $TMP_FILE
  if test $status -gt 0
    echo "Failed to get current variable value"
    set -f create_var
  end

  cp "$TMP_FILE" "$TMP_FILE.before"
  if test -z "$argv[2]"
    vim $TMP_FILE
  else
    echo -n "$argv[2]" > $TMP_FILE
  end

  git diff --ignore-blank-lines --ignore-all-space $TMP_FILE.before $TMP_FILE
  if test $status -eq 0
      echo "No changes found in resulting value."
      _clean_up
      return
  end


  set -f glab_args --type "$type" --scope "$scope"

  if not set -ql _flag_expandable
    set -a -f glab_args "--raw"
  end
  if set -ql _flag_protected
    set -a -f glab_args "--protected"
  end
  if set -ql _flag_masked
    set -a -f glab_args "--masked"
  end


  echo
  if set -qf $create_var
    echo "Creating variable..."
    cat $TMP_FILE | glab variable set $glab_args $var_name
  else
    echo "Updating variable..."
    cat $TMP_FILE | glab variable update $glab_args $var_name
  end

  echo "Done"
end



