# Running Barcelona

## Preparing your environment

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

After running these commands, restart your computer by either running `reboot` or clicking the Apple in the top left and clicking `Restart`.

## Running
Once you've disabled AMFI and SIP, you're read to run Barcelona tools. Just drop them into your PATH, i.e. `/usr/local/bin` or `/opt/<something>/bin` and then run `barcelona-mautrix` or `grapple`.
