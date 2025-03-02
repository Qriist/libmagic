#Requires AutoHotkey v2.0
class libmagic {
    __New(dllPath?,magicPath?) {
        ;find the installed files
        Critical "On"
        try this.dllPath := dllPath
        catch {
            aris := this._findArisInstallDir("Qriist","libmagic")
            this.dllPath := aris "\bin\magic-1.dll"
        }
        try this.magicPath := magicPath
        catch {
            aris := this._findArisInstallDir("Qriist","libmagic")
            this.magicPath := aris "\bin\magic.mgc"
        }
        oldworkingdir := A_WorkingDir
        SplitPath(this.dllPath,,&dllDir)
        SetWorkingDir(dllDir)
        this.dllHandle := DllCall("LoadLibrary", "Str", this.dllPath, "Ptr")
        Critical "Off"

        ;prepare handles
        this.version := DllCall(this.dllPath "\magic_version")

        this.magicHandle := this.magic_open() ;"normal" libmagic calls
        this.magic_load(this.magicHandle,this.magicPath)

        this.mimeHandle := this.magic_open(0x10) ;specifically mime calls
        this.magic_load(this.mimeHandle,this.magicPath)
        
        OnExit (*) => this._cleanup()
    }
    magic(input,magic_cookie := this.magicHandle){
        Switch Type(input){
            case "File":
                filepath := this._GetFilePathFromFileObject(input)
                return this.magic_file(magic_cookie,filepath)
            case "Buffer":
                return this.magic_buffer(magic_cookie,input)
            case "String","Integer":
                ; Calculate required size and allocate a buffer.
                buf := Buffer(StrPut(input))
                ; Copy or convert the string.
                StrPut(input, buf)
                return this.magic_buffer(magic_cookie,buf)
            Default:
                msgbox "Unknown input type."
        }
    }
    mime(input){
        return this.magic(input,this.mimeHandle)
    }

    ;helper
    _cleanup(){
        this.magic_close(this.magicHandle)
        this.magic_close(this.mimeHandle)
    }
    _GetFilePathFromFileObject(FileObject) {
        static GetFinalPathNameByHandleW := DllCall("Kernel32\GetProcAddress", "Ptr", DllCall("Kernel32\GetModuleHandle", "Str", "Kernel32", "Ptr"), "AStr", "GetFinalPathNameByHandleW", "Ptr")

        ; Initialize a buffer to receive the file path
        static bufSize := 65536    ;64kb to accomodate long path names in UTF-16
        buf := Buffer(bufSize)

        ; Call GetFinalPathNameByHandleW
        len := DllCall(GetFinalPathNameByHandleW
            ,   "Ptr", FileObject.handle       ; File handle
            ,   "Ptr", buf         ; Buffer to receive the path
            ,   "UInt", bufSize    ; Size of the buffer (in wchar_t units)
            ,   "UInt", 0          ; Flags (0 for default behavior)
            ,   "UInt")            ; Return length of the file path

        if (len == 0 || len > bufSize)
            throw Error("Failed to retrieve file path or insufficient buffer size", A_LastError)

        ; Return the result as a string
        return StrGet(buf, "UTF-16")
    }
   _findArisInstallDir(user,packageName){ ;dynamically finds a local versioned Aris installation
      If DirExist(A_ScriptDir "\lib\Aris\" user) ;"top level" install
         packageDir := A_ScriptDir "\lib\Aris\" user
      else if DirExist(A_ScriptDir "\..\lib\Aris\" user) ;script one level down
         packageDir := A_ScriptDir "\..\lib\Aris\" user
      else
         return ""
      loop files (packageDir "\" packageName "@*") , "D"{
         ;should end up with the latest installation
         ArisDir := packageDir "\" A_LoopFileName
      }
      return ArisDir
    }

    ;dll functions
    magic_open(flags := 0){
        return DllCall(this.dllPath "\magic_open"
            ,   "UInt", flags
            ,   "Ptr")
    }
    magic_load(magic_cookie,magicPath){
        return DllCall(this.dllPath "\magic_load"
            ,   "Ptr", magic_cookie
            ,   "AStr", magicPath
            ,   "Int")
    }
    magic_file(magic_cookie, filename){
        return DllCall(this.dllPath "\magic_file"
            ,   "Ptr", magic_cookie
            ,   "AStr", filename
            ,   "AStr")
    }
    magic_buffer(magic_cookie, buf){
        return DllCall(this.dllPath "\magic_buffer"
            ,   "Ptr", magic_cookie
            ,   "Ptr", buf
            ,   "UInt", buf.size
            ,   "AStr")
    }
    magic_close(magic_cookie){
        DllCall(this.dllPath "\magic_close"
            ,   "Ptr", magic_cookie)
    }

    /*
        magic_buffer
        magic_check
        magic_close
        magic_compile
        magic_descriptor
        magic_errno
        magic_error
        magic_file
        magic_getflags
        magic_getparam
        magic_getpath
        magic_list
        magic_load
        magic_load_buffers
        magic_open
        magic_setflags
        magic_setparam
        magic_version
    */
}