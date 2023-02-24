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
