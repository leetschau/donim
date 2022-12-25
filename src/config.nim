import std/[json, os]

const
  ConfigFile = "config.json"


type Config* = object
  appHome*: string
  defaultNotebook*: string
  editor*: string
  viewer*: string


proc loadConfigs*(): JsonNode =
  let confPath = getConfigDir() / "donno"
  let confFile = confPath / ConfigFile
  if not fileExists(conffile):
    let defaultConfig = Config(
        appHome: getHomeDir() / ".donno",
        defaultNotebook: "/Misc",
        editor: "nvim",
        viewer: "nvim -R")
    if not dirExists(confPath): createDir(confPath)
    writeFile(confFile, pretty(%* defaultConfig))
  parseFile(confFile)


proc printConfig*(key: string) =
  let confs = loadConfigs()
  if key == "/":
      echo pretty(confs)
  else:
      echo pretty(confs[key])


proc setConfig*(key: string, val:string) =
  var confs = loadConfigs()
  confs[key] = %* val
  let confFile = getConfigDir() / "donno" / ConfigFile
  writeFile(confFile, pretty(confs))
