import ospaths

# Package

version       = "0.0.1"
author        = "Valts"
description   = "Library for writing Emacs modules in Nim"
license       = "MIT"
srcDir        = "src"

# Dependencies

requires "nim >= 0.17.3"

task test, "Run the tester":
  withDir "tests":
    exec "nim c -r tester"

task cleanup, "Clean up files generated by tests":
  for testDir in listDirs("tests"):
    rmDir testDir/"nimcache"
    for file in listFiles(testDir):
      if file.searchExtPos == -1:
        rmFile file