# Patched RosettaLinux

This is a patched version of RosettaLinux from macOS 15.4 beta 4 (24E5238a).

Updates of `RosettaUpdateAuto.pkg` can found at AppleDB by littlebyteorg:  
https://github.com/littlebyteorg/appledb/blob/main/osFiles/Software/Rosetta/24x%20-%2015.x/24E5238a.json

Original patch from https://github.com/CathyKMeow/rosetta-linux-asahi.

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

Recent versions of `rosetta` will yield this additional error:
```
rosetta error: Unexpected ioctl error when communicating with hypervisor: 25
 zsh: trace trap (core dumped)  hello
```

Like above, we can patch it out of existence:
```sh
[0x800000025030]> aaaaaa
[0x800000025030]> s sub.fcn.80000002e984_80000002e984
[0x80000002e984]> pdr
Do you want to print 373 lines? (y/N) y
  ; CALL XREF from sub.entry0_800000025030 @ 0x80000002506c(x)
┌ 1212: sub.fcn.80000002e984_80000002e984 (int64_t arg1, int64_t arg2, int64_t arg3, int64_t arg4);
│ `- args(x0, x1, x2, x3) vars(12:sp[0x8..0x60])
│           0x80000002e984      fd7bbaa9       stp x29, x30, [sp, -0x60]!
│           ...
│           ; CODE XREF from sub.fcn.80000002e984_80000002e984 @ +0x120c(x)
│           0x80000003003c      e80300aa       mov x8, x0
│           0x800000030040      c0fefff0       adrp x0, 0x80000000b000
│           0x800000030044      00041291       add x0, x0, 0x481                 ; 0x80000000b481 ; "Unexpected ioctl error when communicating with hypervisor: %lu\n" ; int64_t arg1
│           0x800000030048      e10308aa       mov x1, x8                        ; int64_t arg2
│           0x80000003004c      18500194       bl sub.fcn.8000000840ac_8000000840ac
└           ...
```

We again convert the CODE XREF to decimal, which is `0x2e984 + 0x120c = 195472`, and patch it with `nop`.
```sh
dd if=<(printf '\x1f\x20\x03\xd5') of=$out/bin/rosetta bs=1 seek=195472 conv=notrunc
```
