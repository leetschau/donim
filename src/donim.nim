import std/[os, strutils]
import notes


const
  NimblePkgVersion {.strdefine.} = ""
  Usage = """
Usage: dn [COMMAND]

Commands:
  add
          add a new note [aliases: a]
  backup
          backup notes to remote repo [aliases: b]
  backup-patch               
          backup unversioned notes to patch file
          /tmp/donno-patch-<git-hash>.tgz [aliases: bp]
  config
          get/set configurations [aliases: conf]
  delete
          delete the selected note [aliases: del]
  edit
          edit the selected note [aliases: e]
  import-patch
          import notes from patch file [aliases: ip]
  list
          list recent updated notes [aliases: l]
  list-notebook
          list notebooks [aliases: lnb]
  search
          search pattern(s) in notes [aliases: s]
  search-complex
          search complex pattern(s) in notes [aliases: sc]
  sync
          sync (pull) notes from remote repo [aliases: syn]
  view
          view the selected note [aliases: v]
  help
          Print this message or the help of the given subcommand(s)

Options:
  -h, --help
          Print help information
  -V, --version
          Print version information
"""

proc parseCmdArgs() =
  let args = commandLineParams()
  if len(args) == 0:
    echo Usage
    quit(0)

  case args[0]
  of "-h", "--help":
    echo Usage
    quit(0)
  of "-V", "--version":
    echo NimblePkgVersion
    quit(0)
  of "l", "list":
    if args.len > 1:
      listNotes(parseInt(args[1]))
    else:
      listNotes()
  of "s", "search":
    # searchNotes(args[1 .. args.high])
    searchNotes(@["aa", "bb"])
  else:
    echo Usage
    quit(0)


when isMainModule:
  parseCmdArgs()

