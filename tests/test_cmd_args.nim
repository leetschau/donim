import parseopt

var p = initOptParser("s word1 word2")
while true:
  p.next()
  case p.kind
  of cmdEnd: break
  of cmdShortOption, cmdLongOption:
    if p.val == "":
      echo "Option: ", p.key
    else:
      echo "Option and value: ", p.key, ", ", p.val
  of cmdArgument:
    echo "Argument: ", p.key
  echo("Hello, World!")
