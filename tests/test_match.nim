include ../src/notes

# let testNotePath = "/home/leo/.donno/repo/note221213161536.md"
let testNotePath = "/home/leo/.donno/repo/note221215135913.md"
# let testWord = "incremental"
let testWord = "moa"
let theNote = loadNote(testNotePath)
let sterm = SearchTerm(field: sContent, kind: stText, item: testWord,
                       ignoreCase: true, wholeWord: false)
echo "Search term: ", sterm
echo "The term matches the note: ", theNote.matches(sterm)
echo "The term matches the body: ", theNote.matchBody(testWord, true, false)
echo "The term matches the note: ", theNote.matchTag("incremental", true, true)


