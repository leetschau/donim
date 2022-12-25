import std/[os, strutils]
import notes
import config


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

  ConfUsage = "Get config: conf -g <key>\nSet config: conf -s <key> <val>"


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
  of "a", "add": addNote()
  of "config", "conf":
    if args.len == 1:
      echo ConfUsage
    elif args.len == 2 and args[1] == "-g":
      printConfig("/")
    elif args.len == 3 and args[1] == "-g":
      printConfig(args[2])
    elif args.len == 4 and args[1] == "-s":
      setConfig(args[2], args[3])
    else:
      echo ConfUsage

  of "e", "edit":
    if args.len > 1:
      editNote(parseInt(args[1]))
    else:
      editNote()
  of "l", "list":
    if args.len > 1:
      listNotes(parseInt(args[1]))
    else:
      listNotes()
  of "s", "search":
     searchNotes(args[1 .. args.high])
  of "v", "view":
    if args.len > 1:
      viewNote(parseInt(args[1]))
    else:
      viewNote()
  else:
    echo Usage
    quit(0)


when isMainModule:
  parseCmdArgs()

