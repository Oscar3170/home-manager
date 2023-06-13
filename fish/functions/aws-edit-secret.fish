function aws-edit-secret --argument-names secret_id
      set file (mktemp)
      aws secretsmanager get-secret-value --secret-id $secret_id | jq -r '.SecretString | fromjson' > $file
      cp $file $file.before
      nvim --cmd ':set ft=json' $file
      git diff --ignore-blank-lines --ignore-all-space $file.before $file
      if test $status -eq 0
          echo No changes found in resulting value.
          rm $file*
          return
      end
      if not jq '.' $file &>/dev/null
          echo
          read _continue -P 'Resulting value is not valid json, would you like to continue? (y,N)'
          if test "$_continue" != "y"
              rm $file*
              return
          end
      end
      echo -e '\nUpdating secret value...'
      aws secretsmanager put-secret-value --secret-id $secret_id --secret-string "$(cat $file)"
      rm $file*
  end
