import std/[algorithm, os, sequtils, strformat, strutils, times]

const
  AppBase = getHomeDir() / ".donno"
  NoteRepo = AppBase / "repo"
  CacheFile = AppBase / ".note.cache"

  DtFmt = "yyyy-MM-dd hh:mm:ss"


type Note = object
    title: string
    tags: seq[string]
    notebook: string
    created: DateTime
    updated: DateTime
    body: string
    filepath: string


proc `$`(note: Note): string =
  let tagstr = note.tags.join("; ")
  let upd = note.updated.format(DtFmt)
  let cre = note.created.format(DtFmt)
  &"{upd} {note.notebook}: {note.title} {cre} [{tagstr}]"


proc loadNote(npath: string): Note =
  let raw = readFile(npath)
  let lines = splitLines(raw)

  result = Note()

  let titleLine = lines[0]
  result.title = titleLine[7 .. titleLine.high]

  let tagLine = lines[1]
  result.tags = tagLine[6 .. tagLine.high].split("; ")

  let nbLine = lines[2]
  result.notebook = nbLine[10 .. nbLine.high]

  let crLine = lines[3]
  result.created = parse(crLine[9 .. crLine.high], "yyyy-MM-dd hh:mm:ss")

  let upLine = lines[4]
  result.updated = parse(upLine[9 .. upLine.high], "yyyy-MM-dd hh:mm:ss")

  result.body = lines[8 .. lines.high].join("\n")

  result.filepath = npath


proc loadNotes(repoPath: string): seq[Note] =
  ## Load all markdown file from the 'repo_path' and sort with updated time
  let noteFiles = toSeq(walkFiles(repoPath / "*.md"))
  result = map(noteFiles, loadNote)
  result.sort(proc (x, y: Note): int = result = cmp(x.updated, y.updated),
              order = SortOrder.Descending)


proc displayNotes(notes: seq[Note]): string =
  ## Extract meta-data from notes, display on the console
  ## and save to disk for later usage
  writeFile(CacheFile, notes.mapIt(it.filepath).join("\n"))
  let header = "No.   Updated, Notebook, Title, Created, Tags\n"
  let idx = toSeq(1 .. notes.len)
  header & zip(idx, notes).mapIt($it[0] & ". " & $(it[1])).join("\n")


proc listNotes*(num: int = 5) =
  let notes = loadNotes(NoteRepo)
  echo displayNotes(notes[0 ..< num])


proc searchNotes*(terms: seq[string]) =
  echo "search ", terms, " in note repo"


