#Requires AutoHotkey v2.0
RunWait("git pull", "C:\dev\vcpkg")
RunWait("C:\dev\vcpkg\bootstrap-vcpkg.bat", "C:\dev\vcpkg")
try DirDelete(A_ScriptDir "\build\", 1)
vcpkg := "vcpkg install "
    . "libmagic[bzip2,lzma,zlib,zstd] "
    . "--x-install-root=build"
RunWait(vcpkg)

FileMove(A_ScriptDir "\build\x64-windows\tools\libmagic\share\misc\*.mgc", A_ScriptDir "\bin\", 1)
FileMove(A_ScriptDir "\build\x64-windows\tools\libmagic\bin\*.dll", A_ScriptDir "\bin\", 1)