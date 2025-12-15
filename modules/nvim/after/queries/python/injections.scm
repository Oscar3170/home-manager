((string (string_content) @injection.content)
  (#match? @injection.content "^( |\n|\t)*(SELECT|select).*")
  (#set! injection.language "sql"))
