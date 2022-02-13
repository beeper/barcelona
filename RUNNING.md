# Running Barcelona on MacOS

## Preparing your environment

> Heads up - Barcelona requires you to disable AMFI, SIP, and weaken security around what processes can communicate with system services. This is inheritently unsafe, and there's a reason this is not enabled by default. However, there is no other way at this time to cleanly and persistently get this level of access to the daemons. If you are uncomfortable with this, then Barcelona is not for you. Barcelona is designed from the start to run on weakened systems, and there are no plans to attempt to support factory-default macOS.

### AMFI & SIP
Barcelona requires [AMFI](https://www.theiphonewiki.com/wiki/AppleMobileFileIntegrity) and [SIP](https://support.apple.com/en-us/HT204899) to be disabled so that it can communicate with IMDPersistenceAgent and imagent, among other AppleInternal daemons.

#### Apple Silicon
To disable AMFI on a Mac running Apple Silicon, run the following from your Terminal in **normal mode**.

```bash
sudo nvram boot-args='amfi_get_out_of_my_way=1'
```

After running this command, [restart your computer into Recovery Mode](https://support.apple.com/guide/mac-help/macos-recovery-a-mac-apple-silicon-mchl82829c17/mac).

Once in recovery mode, [set your system security policy to **permissive security**](https://support.apple.com/guide/security/startup-disk-security-policy-control-sec7d92dc49f/web).

Reboot your computer, and you should be ready to run Barcelona.

#### Intel
To disable AMFI on a Mac running Intel, run the following from your Terminal in [**recovery mode**](https://support.apple.com/guide/mac-help/use-macos-recovery-on-an-intel-based-mac-mchl338cf9a8/mac)

```bash
nvram boot-args='amfi_get_out_of_my_way=1'
csrutil disable
```

### XPC Security
In order for Barcelona to communicate with IMDPersistenceAgent, you must install [com.apple.security.xpc.plist](com.apple.security.xpc.plist) to `/Library/Preferences/com.apple.security.xpc.plist`. This preference file instructs XPC services to allow non-Apple agents to connect to them. Obviously, this poses a security risk, as does disabling AMFI and SIP.

After running these commands, restart your computer by either running `reboot` or clicking the Apple in the top left and clicking `Restart`.

## Running
Once you've disabled AMFI and SIP, you're read to run Barcelona tools. Just drop them into your PATH, i.e. `/usr/local/bin` or `/opt/<something>/bin` and then run `barcelona-mautrix` or `grapple`.

# Running Barcelona on iOS

First of all you need to have a jailbroken iOS device for this. The following documentation has been tested on an iPhone 7 running `14.7.1` using the [checkra1n jailbreak](https://checkra.in/). 

Once jailbroken, install OpenSSH Server in Cydia, ssh to your iPhone (make sure to change passwords for the users `root` and `mobile`!).

On your phone, `cd` into `/private/var/` and create a folder `barcelona`, this is where we will install everything into.

First I'd suggest testing if you can get Grapple to work, which has no other dependencies:

- `mkdir -p /private/var/barcelona`
- `cd /private/var/barcelona`
- `wget https://jank.crap.studio/job/barcelona/job/mautrix/lastSuccessfulBuild/artifact/ios-grapple`
- `chmod +x ios-grapple`
- `./ios-grapple chat list`

Once that's working we can continue setting up Barcelona with mautrix-imessage. For this you should first download it and make it exectuable as well:

- `wget https://jank.crap.studio/job/barcelona/job/mautrix/lastSuccessfulBuild/artifact/ios-barcelona-mautrix`
- `chmod +x ios-barcelona-mautrix`
- `./ios-barcelona-mautrix`

You should now see some output like the following:
```
{"command":"log","data":{"metadata":{"line":"43","function":"bootstrap()","fileID":"barcelona_mautrix\/BarcelonaMautrix.swift"},"message":"Bootstrapping","level":"INFO","module":"ERBarcelonaManager"}}{"command":"log","data":{"metadata":{"line":"169","function":"apply()","fileID":"Barcelona\/HookManager.swift"},"message":"Applying hooks","level":"DEBUG","module":"Hooks"}}{"command":"log","data":{"metadata":{"fileID":"Barcelona\/HookManager.swift","function":"apply()","line":"174"},"message":"Applying hook 1 of 5","level":"DEBUG","module":"Hooks"}}{"command":"log","data":{"metadata":{"fileID":"Barcelona\/HookManager.swift","function":"apply()","line":"174"},"message":"Applying hook 2 of 5","level":"DEBUG","module":"Hooks"}}{"command":"log","data":{"metadata":{"fileID":"Barcelona\/HookManager.swift","line":"174","function":"apply()"},"message":"Applying hook 3 of 5","level":"DEBUG","module":"Hooks"}}{"command":"log","data":{"metadata":{"line":"174","function":"apply()","fileID":"Barcelona\/HookManager.swift"},"message":"Applying hook 4 of 5","level":"DEBUG","module":"Hooks"}}{"command":"log","data":{"metadata":{"fileID":"Barcelona\/HookManager.swift","function":"apply()","line":"174"},"message":"Applying hook 5 of 5","level":"DEBUG","module":"Hooks"}}{"command":"log","data":{"metadata":{"fileID":"Barcelona\/HookManager.swift","function":"apply()","line":"181"},"message":"All hooks applied","level":"DEBUG","module":"Hooks"}}{"command":"log","data":{"metadata":{"fileID":"Barcelona\/BarcelonaManager.swift","function":"BLBootstrapController(_:_:)","line":"86"},"message":"Connecting to daemon...","level":"INFO","module":"BarcelonaManager"}}{"command":"log","data":{"metadata":{"fileID":"Barcelona\/CBDaemonListener.swift","function":"setupComplete(_:info:)","line":"322"},"message":"setup: true","level":"DEBUG","module":"ERDaemonListener"}}{"command":"log","data":{"metadata":{"line":"157","fileID":"Barcelona\/CBLinking.swift","function":"CBWeakLink(against:options:)"},"message":"Selecting PNCopyBestGuessCountryCodeForNumber for linker candidate","level":"DEBUG","module":"CBLinking"}}{"command":"log","data":{"metadata":{"fileID":"Barcelona\/BarcelonaManager.swift","function":"BLBootstrapController(_:_:)","line":"91"},"message":"Connected to daemon. Fetching nicknames...","level":"INFO","module":"BarcelonaManager"}}{"command":"log","data":{"metadata":{"fileID":"Barcelona\/BarcelonaManager.swift","function":"BLBootstrapController(_:_:)","line":"95"},"message":"Fetched nicknames. Setting up IMContactStore...","level":"INFO","module":"BarcelonaManager"}}{"command":"log","data":{"metadata":{"fileID":"Barcelona\/BarcelonaManager.swift","function":"BLBootstrapController(_:_:)","line":"99"},"message":"Connected.","level":"INFO","module":"BarcelonaManager"}}{"command":"log","data":{"metadata":{"line":"58","function":"bootstrap()","fileID":"barcelona_mautrix\/BarcelonaMautrix.swift"},"message":"BLMautrix is ready","level":"INFO","module":"ERBarcelonaManager"}}{"command":"log","data":{"metadata":{"line":"63","function":"bootstrap()","fileID":"barcelona_mautrix\/BarcelonaMautrix.swift"},"message":"BLMautrix event handler is running","level":"INFO","module":"ERBarcelonaManager"}}
```

Exit this using Ctrl+C as we want `mautrix-imessage` to communicate with that deamon via IPC.

For this, fetch the latest mautrix-imessage binary for your platform:
- `curl -k  -L https://mau.dev/mautrix/imessage/-/jobs/artifacts/master/download?job=build+ios+arm64 -o mautrix-imessage-ios-arm64.zip`
- `unzip mautrix-imessage-ios-arm64.zip`
- `mv mautrix-imessage-ios-arm64/* .`
- `chmod +x mautrix-imessage`

Now copy `example-config.yaml` to `config.yaml` and add your configuration as described in steps 1-5 [here](https://docs.mau.fi/bridges/go/imessage/ios/setup.html). You want to use `platform: mac-nosip` and `imessage_rest_path: /private/var/barcelona/ios-barcelona-mautrix`.

Next, if you try to run `./mautrix-imessage` you'll get `Killed: 9`. This is because of how iOS security sandboxing works, this binary has no permissions to do IPC.

To fix this, create a file called `entitlements.xml` with the following contents (you might not need all these entitlements, I just copied what debugserver uses):

```
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>platform-application</key>
    <true/>
    <key>com.apple.private.security.no-container</key>
    <true/>
    <key>com.apple.private.skip-library-validation</key>
    <true/>
    <key>com.apple.backboardd.debugapplications</key>
    <true/>
    <key>com.apple.backboardd.launchapplications</key>
    <true/>
    <key>com.apple.diagnosticd.diagnostic</key>
    <true/>
    <key>com.apple.frontboard.debugapplications</key>
    <true/>
    <key>com.apple.frontboard.launchapplications</key>
    <true/>
    <key>com.apple.security.network.client</key>
    <true/>
    <key>com.apple.security.network.server</key>
    <true/>
    <key>com.apple.springboard.debugapplications</key>
    <true/>
    <key>com.apple.system-task-ports</key>
    <true/>
    <key>get-task-allow</key>
    <true/>
    <key>run-unsigned-code</key>
    <true/>
    <key>task_for_pid-allow</key>
    <true/>
</dict>
</plist>
```

Next, you need to allow these entitlements for `mautrix-imessage`: `ldid -Sentitlements.xml mautrix-imessage`.

After that you install `tmux` via cydia, run `tmux` to start a tmux session and then run `./mautrix-imessage`. Once you confirmed that everthing works, detach from the tmux session (`ctrl-b` followed by `d`) and enjoy the running bridge!


## Troubleshooting

```
panic: runtime error: invalid memory address or nil pointer dereference
[signal SIGSEGV: segmentation violation code=0x2 addr=0x8 pc=0x1053a6eb8]

goroutine 26 [running]:
os.(*ProcessState).exited(...)
        /opt/homebrew/Cellar/go/1.17.6/libexec/src/os/exec_posix.go:84
os.(*ProcessState).Exited(...)
        /opt/homebrew/Cellar/go/1.17.6/libexec/src/os/exec.go:153
go.mau.fi/mautrix-imessage/imessage/mac-nosip.(*MacNoSIPConnector).Start.func1(0x1301311d0, 0x13007c360)
        /Users/ci/builds/YUMeaPfZ/0/mautrix/imessage/imessage/mac-nosip/nosip.go:82 +0x38
created by go.mau.fi/mautrix-imessage/imessage/mac-nosip.(*MacNoSIPConnector).Start
        /Users/ci/builds/YUMeaPfZ/0/mautrix/imessage/imessage/mac-nosip/nosip.go:80 +0x2bc
```

This is a currently known issue when receiving or processing attachments (links, images), tracked in [#32](https://github.com/open-imcore/barcelona/issues/35)

#### Things look strange

Check if a second copy if barcelona is working:
`ps aux | grep ios-barcelona-mautrix`

If yes, stop mautrix-imessage, kill all barcelonas and start from scratch.
