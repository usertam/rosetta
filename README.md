# Patched RosettaLinux

This is a patched version of RosettaLinux from macOS 15.3.2 (24D81).

Updates of `RosettaUpdateAuto.pkg` can found at AppleDB by littlebyteorg:  
https://github.com/littlebyteorg/appledb/blob/main/osFiles/Software/Rosetta/24x%20-%2015.x/24D81.json

Hack from https://github.com/CathyKMeow/rosetta-linux-asahi.

## Patching
We use radare2 on the `rosetta` binary. Inside `entry0`, only one function is called. Seek to that function `0x80000002e984`, and locate the string `"Rosetta is only intended to run on..."`.
```sh
$ r2 rosetta
[0x800000025030]> aaaaaa
INFO: Analyze...
[0x800000025030]> pdf
            ;-- entry0:
            ;-- pc:
┌ 176: sub.entry0_800000025030 (int64_t arg_0h, int64_t arg_8h);
│ `- args(sp[0x0..0x8]) vars(3:sp[0x10..0x20])
│           0x800000025030      f3030091       mov x19, sp
│           ...
│           0x800000025068      e8030091       mov x8, sp
│           0x80000002506c      46260094       bl sub.fcn.80000002e984_80000002e984
│           0x800000025070      f60340f9       ldr x22, [sp]
└           ...
[0x800000025030]> s sub.fcn.80000002e984_80000002e984
[0x80000002e984]> pdr
Do you want to print 373 lines? (y/N) y
  ; CALL XREF from sub.entry0_800000025030 @ 0x80000002506c(x)
┌ 1212: sub.fcn.80000002e984_80000002e984 (int64_t arg1, int64_t arg2, int64_t arg3, int64_t arg4);
│ `- args(x0, x1, x2, x3) vars(12:sp[0x8..0x60])
│           0x80000002e984      fd7bbaa9       stp x29, x30, [sp, -0x60]!
│           ...
│           ; CODE XREFS from sub.fcn.80000002e984_80000002e984 @ 0x80000002e9f0(x), 0x80000002ea0c(x)
│           0x80000002fdb0      c0feffd0       adrp x0, 0x800000009000
│           0x80000002fdb4      00300c91       add x0, x0, 0x30c                 ; 0x80000000930c ; "Rosetta is only intended to run on Apple Silicon with a macOS host using Virtualization.framework with Rosetta mode enabled" ; int64_t arg1
│           0x80000002fdb8      bd500194       bl sub.fcn.8000000840ac_8000000840ac
└           ...
```
Above the section, we see two CODE XREFS above pointing to the code, which are `0x80000002e9f0` and `0x80000002ea0c`. We ignore the `0x8000000` prefix and convert only the offset to decimal.

We get `0x2e9f0 = 190960` and `0x2ea0c = 190988`. Just replace each 4 bytes at two addresses with `nop`.
```sh
dd if=<(printf '\x1f\x20\x03\xd5') of=$out/bin/rosetta bs=1 seek=190960 conv=notrunc
dd if=<(printf '\x1f\x20\x03\xd5') of=$out/bin/rosetta bs=1 seek=190988 conv=notrunc
```
