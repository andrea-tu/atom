fs = require 'fs-plus'
path = require 'path'
season = require 'season'
temp = require('temp').track()
runAtom = require './helpers/start-atom'

describe "Smoke Test", ->
  return unless process.platform is 'darwin' # Fails on win32

  atomHome = temp.mkdirSync('atom-home')

  beforeEach ->
    jasmine.useRealClock()
    season.writeFileSync(path.join(atomHome, 'config.cson'), {
      '*': {
        welcome: {showOnStartup: false},
        core: {
          telemetryConsent: 'no',
          disabledPackages: ['github']
        }
      }
    })

  it "can open a file in Atom and perform basic operations on it", ->
    tempDirPath = temp.mkdirSync("empty-dir")
    filePath = path.join(tempDirPath, "new-file")

    fs.writeFileSync filePath, "", {encoding: "utf8"}

    runAtom [filePath], {ATOM_HOME: atomHome}, (client) ->
      client
        .treeViewRootDirectories()
        .then ({value}) -> expect(value).toEqual([])
        .waitForExist("atom-text-editor", 5000)
        .then (exists) -> expect(exists).toBe true
        .waitForPaneItemCount(1, 1000)
        .click("atom-text-editor")
        .waitUntil((-> @execute(-> document.activeElement.closest('atom-text-editor'))), 5000)
        .keys("Hello!")
        .execute -> atom.workspace.getActiveTextEditor().getText()
        .then ({value}) -> expect(value).toBe "Hello!"
        .dispatchCommand("editor:delete-line")
