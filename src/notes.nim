import std/[algorithm, json, os, sequtils, strformat, strutils, times]
import config

const
  DtFmt = "yyyy-MM-dd HH:mm:ss"
  DateFmt = "yyyy-MM-dd"
  Header = "No.    Updated  Notebook  Title  Created  Tags\n"
  TempNotePath = "/tmp/dsnote-tmp.md"
  NotePrefix = "repo/note"


type
  Note = object
    title: string
    tags: seq[string]
    notebook: string
    created: DateTime
    updated: DateTime
    body: string
    filepath: string

  SearchField = enum sTitle, sTag, sNotebook, sCreated, sUpdated, sContent

  SearchType = enum stText, stTime

  SearchTerm = object
    field: SearchField
    case kind: SearchType
    of stText:
      item: string
      ignoreCase: bool
      wholeWord: bool
    of stTime:
      tpoint: DateTime
      before: bool  # "true" means the note under investigation was created
                    # before the filtering time point specified by the user

func `$`(note: Note): string =
  let tagstr = note.tags.join("; ")
  let upd = note.updated.format(DateFmt)
  let cre = note.created.format(DateFmt)
  &"{upd} {note.notebook}: {note.title} {cre} [{tagstr}]"

func matchTitle(note: Note,
                term: string,
                ignoreCase: bool,
                matchWholeWord: bool): bool =
  let token = (if ignoreCase: term.toLowerAscii() else: term)
  let target = (if ignoreCase: note.title.toLowerAscii() else: note.title)
  if matchWholeWord:
    let titlews = target.split(" ")
    token in titlews
  else:
    token in target

func matchTag(note: Note,
              term: string,
              ignoreCase: bool,
              matchWholeWord: bool): bool =
  let token = (if ignoreCase: term.toLowerAscii() else: term)
  let tagline = (if ignoreCase: note.tags.join(" ").toLowerAscii()
                 else: note.tags.join(" "))
  if matchWholeWord:
    token in tagline.split(" ")
  else:
    token in tagline

func matchNotebook(note: Note,
                   term: string,
                   ignoreCase: bool,
                   matchWholeWord: bool): bool =
  let token = (if ignoreCase: term.toLowerAscii() else: term)
  let target = (if ignoreCase: note.notebook.toLowerAscii() else: note.notebook)
  if matchWholeWord:
    let pathws = target.split("/")
    token in pathws
  else:
    token in target

func matchBody(note: Note,
               term: string,
               ignoreCase: bool,
               matchWholeWord: bool): bool =
  let token = (if ignoreCase: term.toLowerAscii() else: term)
  let target = (if ignoreCase: note.body.toLowerAscii() else: note.body)
  if matchWholeWord:
    let bodyws = target.split(" ")
    token in bodyws
  else:
    token in target

func matches(note: Note, term: SearchTerm): bool =
  case term.kind
  of stText:
    case term.field
    of sTitle: note.matchTitle(term.item, term.ignoreCase, term.wholeWord)
    of sTag: note.matchTag(term.item, term.ignoreCase, term.wholeWord)
    of sNotebook: note.matchNotebook(term.item, term.ignoreCase, term.wholeWord)
    of sContent: 
      note.matchTitle(term.item, term.ignoreCase, term.wholeWord) or
      note.matchTag(term.item, term.ignoreCase, term.wholeWord) or
      note.matchNotebook(term.item, term.ignoreCase, term.wholeWord) or
      note.matchBody(term.item, term.ignoreCase, term.wholeWord) or
      (term.item in $note.created) or (term.item in $note.updated)
    else: false
  of stTime:
    case term.field
    of sCreated:
      if term.before:
        note.created < term.tpoint
      else:
        note.created >= term.tpoint
    of sUpdated:
      if term.before:
        note.updated < term.tpoint
      else:
        note.updated >= term.tpoint
    else: false


proc getCacheFilePath(): string =
  let confs = to(loadConfigs(), Config)
  confs.appHome / ".note.cache"


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


proc loadNotes(): seq[Note] =
  ## Load all markdown file from the 'repo_path' and sort with updated time
  let confs = to(loadConfigs(), Config)
  let noteFiles = toSeq(walkFiles(confs.appHome / "repo" / "*.md"))
  result = map(noteFiles, loadNote)
  result.sort(proc (x, y: Note): int = result = cmp(x.updated, y.updated),
              order = SortOrder.Descending)


proc displayNotes(notes: seq[Note]): string =
  ## Extract meta-data from notes, display on the console
  ## and save to disk for later usage
  writeFile(getCacheFilePath(), notes.mapIt(it.filepath).join("\n"))
  let idx = toSeq(1 .. notes.len)
  Header & zip(idx, notes).mapIt(&"{$it[0]:>2}" & ". " & $(it[1])).join("\n")


proc buildSearchTerm(inp: string): SearchTerm =
  let segs = inp.split(":")
  if segs.len == 1:
    return SearchTerm(field: sContent, kind: stText, item: inp,
                      ignoreCase: true, wholeWord: false)
  elif segs.len == 2:
    case segs[0]
    of "ti": return SearchTerm(field: sTitle, kind: stText,
               item: segs[1], ignoreCase: true, wholeWord: false)
    of "ta": return SearchTerm(field: sTag, kind: stText,
               item: segs[1], ignoreCase: true, wholeWord: false)
    of "nb": return SearchTerm(field: sNotebook, kind: stText,
               item: segs[1], ignoreCase: true, wholeWord: false)
    of "cr": return SearchTerm(field: sCreated, kind: stTime,
               tpoint: parse(segs[1], DateFmt), before: false)
    of "up": return SearchTerm(field: sUpdated, kind: stTime,
               tpoint: parse(segs[1], DateFmt), before: false)
  elif segs.len == 3:
    case segs[0]
    of "ti": result =
      SearchTerm(field: sTitle, kind: stText, item: segs[1])
    of "ta": result =
      SearchTerm(field: sTag, kind: stText, item: segs[1])
    of "nb": result =
      SearchTerm(field: sNotebook, kind: stText, item: segs[1])
    of "cr": result =
      SearchTerm(field: sCreated, kind: stTime, tpoint: parse(segs[1], DateFmt))
    of "up": result =
      SearchTerm(field: sUpdated, kind: stTime, tpoint: parse(segs[1], DateFmt))
    case segs[2]
    of "i", "W", "iW", "Wi": result.ignoreCase = true; result.wholeWord = false
    of "I", "IW", "WI": result.ignoreCase = false; result.wholeWord = false
    of "w", "iw", "wi": result.ignoreCase = true; result.wholeWord = true
    of "Iw", "wI": result.ignoreCase = false; result.wholeWord = true
    of "b": result.before = true
    of "B": result.before = false


proc saveNote(fpath: string, note: Note) =
  let tagline = note.tags.join("; ")
  let notestr = &"Title: {note.title}\nTags: {tagline}\n" &
    &"Notebook: {note.notebook}\nCreated: {note.created.format(DtFmt)}\n" &
    &"Updated: {note.updated.format(DtFmt)}\n\n------\n\n{note.body}"
  writeFile(fpath, notestr)


proc addNote*() =
  let confs = to(loadConfigs(), Config)
  let noteTemplate = &"Title: \nTags: \nNotebook: {confs.defaultNotebook}\n" &
    &"Created: {now().format(DtFmt)}\nUpdated: {now().format(DtFmt)}" &
    "\n\n------\n\n"
  writeFile(TempNotePath, noteTemplate)
  let ret = execShellCmd(&"{confs.editor} {TempNotePath}")
  if ret != 0:
    echo "Error occured when editing file, quit"
    quit(1)
  let ts = now().format("yyMMddHHmmss")
  let newNote = loadNote(TempNotePath)
  let notePath = NotePrefix & ts & ".md"
  saveNote(confs.appHome / notePath, newNote)


proc editNote*(num: int = 1) =
  let confs = to(loadConfigs(), Config)
  let notePaths = readFile(getCacheFilePath()).split("\n")
  let fpath = notePaths[num - 1]
  let oNote = loadNote(fpath)
  let nNote = Note(title: oNote.title, tags: oNote.tags,
                   notebook: oNote.notebook, created: oNote.created,
                   updated: now(), body: oNote.body, filepath: fpath)
  saveNote(fpath, nNote)
  let ret = execShellCmd(&"{confs.editor} {fpath}")
  if ret != 0:
    echo "Error occured when editing file, quit"
    quit(1)


proc listNotes*(num: int = 5) =
  let notes = loadNotes()
  echo displayNotes(notes[0 ..< num])


proc searchNotes*(words: seq[string]) =
  let terms = map(words, buildSearchTerm)
  let notes = loadNotes()
  let matchedNotes = foldl(terms, a.filterIt(it.matches(b)), notes)
  echo displayNotes(matchedNotes)


proc viewNote*(num: int = 1) =
  let confs = to(loadConfigs(), Config)
  let notePaths = readFile(getCacheFilePath()).split("\n")
  let fpath = notePaths[num - 1]
  discard execShellCmd(&"{confs.viewer} {fpath}")
