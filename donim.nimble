# Package

version           = "0.1.0"
author            = "Clouds"
description       = "donno in nim"
license           = "MIT"
srcDir            = "src"
bin               = @["donim"]
namedBin["donim"] = "dn"
binDir            = "build"


# Dependencies

requires "nim >= 1.6.6"
