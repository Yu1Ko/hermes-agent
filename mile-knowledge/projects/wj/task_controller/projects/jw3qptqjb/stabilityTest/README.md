# Android ASAN符号解析工具

# 简介

默认情况下ASAN为了效率在错误报告里面回溯的堆栈是不会解析符号的，官方提供一些解析符号的方案（具体参考 [LLVM-ASAN-Symbolizing the Reports](https://clang.llvm.org/docs/AddressSanitizer.html#symbolizing-the-reports) ），但不是很适合Android平台，因此本工具专门用来解析Android平台下的ASAN报告中的堆栈符号。

​            

# 使用方法

```
python.exe android_asan_symbolize.py --input <log_file> --symbols_dir <symbols_dir>
```

参数说明：

- `input`: Android的logcat输出文件，可使用 `adb logcat > log.txt` 来得到。
- `symbols_dir`: 符号目录，里面直接放置所有的符号文件so即可，文件名必须运行时的文件名一致。


除了可以从log文件进行输入，还可以直接用 `adb logcat` 作为输出，即实时的获取 `adb logcat` 的输出，一旦有发现 `asan` 的错误日志出来，则马上会去解析错误日志里面的堆栈符号。

```
python.exe android_asan_symbolize.py --adb --symbols_dir <symbols_dir>
```

> NOTE: 这个要求系统环境变量 `PATH` 里面能找到 `adb.exe` (本工具不带adb)。
​        

# 使用示例

INPUT: `logcat.txt` :

```
2022-03-21 14:49:04.211 8055-8055/com.lds.asandemo I/com.lds.asandemo: =================================================================
2022-03-21 14:49:04.212 8055-8055/com.lds.asandemo I/com.lds.asandemo: ==8055==ERROR: AddressSanitizer: heap-use-after-free on address 0x003100000015 at pc 0x007f8bff5c74 bp 0x007fe2614550 sp 0x007fe2614548
2022-03-21 14:49:04.212 8055-8055/com.lds.asandemo I/com.lds.asandemo: READ of size 1 at 0x003100000015 thread T0
2022-03-21 14:49:04.229 8055-8055/com.lds.asandemo I/com.lds.asandemo:     #0 0x7f8bff5c73  (/data/app/com.lds.asandemo-2/lib/arm64/libnative-lib.so+0xc73)
2022-03-21 14:49:04.229 8055-8055/com.lds.asandemo I/com.lds.asandemo:     #1 0x7f8bff5e67  (/data/app/com.lds.asandemo-2/lib/arm64/libnative-lib.so+0xe67)
2022-03-21 14:49:04.229 8055-8055/com.lds.asandemo I/com.lds.asandemo:     #2 0x7f72cf57b3  (/data/app/com.lds.asandemo-2/oat/arm64/base.odex+0x4207b3)
2022-03-21 14:49:04.229 8055-8055/com.lds.asandemo I/com.lds.asandemo: 0x003100000015 is located 5 bytes inside of 10-byte region [0x003100000010,0x00310000001a)
2022-03-21 14:49:04.229 8055-8055/com.lds.asandemo I/com.lds.asandemo: freed by thread T0 here:
2022-03-21 14:49:04.229 8055-8055/com.lds.asandemo I/com.lds.asandemo:     #0 0x7f71f265a7  (/data/app/com.lds.asandemo-2/lib/arm64/libclang_rt.asan-aarch64-android.so+0x9f5a7)
2022-03-21 14:49:04.229 8055-8055/com.lds.asandemo I/com.lds.asandemo:     #1 0x7f8bff5c17  (/data/app/com.lds.asandemo-2/lib/arm64/libnative-lib.so+0xc17)
2022-03-21 14:49:04.230 8055-8055/com.lds.asandemo I/com.lds.asandemo:     #2 0x7f8bff5e67  (/data/app/com.lds.asandemo-2/lib/arm64/libnative-lib.so+0xe67)
2022-03-21 14:49:04.230 8055-8055/com.lds.asandemo I/com.lds.asandemo:     #3 0x7f72cf57b3  (/data/app/com.lds.asandemo-2/oat/arm64/base.odex+0x4207b3)
2022-03-21 14:49:04.230 8055-8055/com.lds.asandemo I/com.lds.asandemo:     #4 0x7f8d0b7283  (/system/lib64/libart.so+0xdf283)
2022-03-21 14:49:04.230 8055-8055/com.lds.asandemo I/com.lds.asandemo:     #5 0x7f8d26a603  (/system/lib64/libart.so+0x292603)
2022-03-21 14:49:04.230 8055-8055/com.lds.asandemo I/com.lds.asandemo:     #6 0x7f8d2635df  (/system/lib64/libart.so+0x28b5df)
2022-03-21 14:49:04.230 8055-8055/com.lds.asandemo I/com.lds.asandemo:     #7 0x7f8d533be7  (/system/lib64/libart.so+0x55bbe7)
2022-03-21 14:49:04.230 8055-8055/com.lds.asandemo I/com.lds.asandemo:     #8 0x7f8d0a0d17  (/system/lib64/libart.so+0xc8d17)
2022-03-21 14:49:04.230 8055-8055/com.lds.asandemo I/com.lds.asandemo:     #9 0x7f8d23c93f  (/system/lib64/libart.so+0x26493f)
2022-03-21 14:49:04.231 8055-8055/com.lds.asandemo I/com.lds.asandemo:     #10 0x7f8d5250ff  (/system/lib64/libart.so+0x54d0ff)
2022-03-21 14:49:04.231 8055-8055/com.lds.asandemo I/com.lds.asandemo:     #11 0x7f8d0b3caf  (/system/lib64/libart.so+0xdbcaf)
2022-03-21 14:49:04.231 8055-8055/com.lds.asandemo I/com.lds.asandemo: previously allocated by thread T0 here:
2022-03-21 14:49:04.231 8055-8055/com.lds.asandemo I/com.lds.asandemo:     #0 0x7f71f268bf  (/data/app/com.lds.asandemo-2/lib/arm64/libclang_rt.asan-aarch64-android.so+0x9f8bf)
2022-03-21 14:49:04.231 8055-8055/com.lds.asandemo I/com.lds.asandemo:     #1 0x7f8bff5c0b  (/data/app/com.lds.asandemo-2/lib/arm64/libnative-lib.so+0xc0b)
2022-03-21 14:49:04.231 8055-8055/com.lds.asandemo I/com.lds.asandemo:     #2 0x7f8bff5e67  (/data/app/com.lds.asandemo-2/lib/arm64/libnative-lib.so+0xe67)
2022-03-21 14:49:04.231 8055-8055/com.lds.asandemo I/com.lds.asandemo:     #3 0x7f72cf57b3  (/data/app/com.lds.asandemo-2/oat/arm64/base.odex+0x4207b3)
2022-03-21 14:49:04.231 8055-8055/com.lds.asandemo I/com.lds.asandemo:     #4 0x7f8d0b7283  (/system/lib64/libart.so+0xdf283)
2022-03-21 14:49:04.232 8055-8055/com.lds.asandemo I/com.lds.asandemo:     #5 0x7f8d26a603  (/system/lib64/libart.so+0x292603)
2022-03-21 14:49:04.232 8055-8055/com.lds.asandemo I/com.lds.asandemo:     #6 0x7f8d2635df  (/system/lib64/libart.so+0x28b5df)
2022-03-21 14:49:04.232 8055-8055/com.lds.asandemo I/com.lds.asandemo:     #7 0x7f8d533be7  (/system/lib64/libart.so+0x55bbe7)
2022-03-21 14:49:04.232 8055-8055/com.lds.asandemo I/com.lds.asandemo:     #8 0x7f8d0a0d17  (/system/lib64/libart.so+0xc8d17)
2022-03-21 14:49:04.232 8055-8055/com.lds.asandemo I/com.lds.asandemo:     #9 0x7f8d23c93f  (/system/lib64/libart.so+0x26493f)
2022-03-21 14:49:04.232 8055-8055/com.lds.asandemo I/com.lds.asandemo:     #10 0x7f8d5250ff  (/system/lib64/libart.so+0x54d0ff)
2022-03-21 14:49:04.232 8055-8055/com.lds.asandemo I/com.lds.asandemo:     #11 0x7f8d0b3caf  (/system/lib64/libart.so+0xdbcaf)
2022-03-21 14:49:04.233 8055-8055/com.lds.asandemo I/com.lds.asandemo: SUMMARY: AddressSanitizer: heap-use-after-free (/data/app/com.lds.asandemo-2/lib/arm64/libnative-lib.so+0xc73) 
2022-03-21 14:49:04.233 8055-8055/com.lds.asandemo I/com.lds.asandemo: Shadow bytes around the buggy address:
2022-03-21 14:49:04.233 8055-8055/com.lds.asandemo I/com.lds.asandemo:   0x00161fffffb0: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
2022-03-21 14:49:04.233 8055-8055/com.lds.asandemo I/com.lds.asandemo:   0x00161fffffc0: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
2022-03-21 14:49:04.233 8055-8055/com.lds.asandemo I/com.lds.asandemo:   0x00161fffffd0: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
2022-03-21 14:49:04.233 8055-8055/com.lds.asandemo I/com.lds.asandemo:   0x00161fffffe0: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
2022-03-21 14:49:04.233 8055-8055/com.lds.asandemo I/com.lds.asandemo:   0x00161ffffff0: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
2022-03-21 14:49:04.233 8055-8055/com.lds.asandemo I/com.lds.asandemo: =>0x001620000000: fa fa[fd]fd fa fa fa fa fa fa fa fa fa fa fa fa
2022-03-21 14:49:04.233 8055-8055/com.lds.asandemo I/com.lds.asandemo:   0x001620000010: fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa
2022-03-21 14:49:04.233 8055-8055/com.lds.asandemo I/com.lds.asandemo:   0x001620000020: fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa
2022-03-21 14:49:04.233 8055-8055/com.lds.asandemo I/com.lds.asandemo:   0x001620000030: fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa
2022-03-21 14:49:04.233 8055-8055/com.lds.asandemo I/com.lds.asandemo:   0x001620000040: fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa
2022-03-21 14:49:04.233 8055-8055/com.lds.asandemo I/com.lds.asandemo:   0x001620000050: fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa
2022-03-21 14:49:04.233 8055-8055/com.lds.asandemo I/com.lds.asandemo: Shadow byte legend (one shadow byte represents 8 application bytes):
2022-03-21 14:49:04.233 8055-8055/com.lds.asandemo I/com.lds.asandemo:   Addressable:           00
2022-03-21 14:49:04.233 8055-8055/com.lds.asandemo I/com.lds.asandemo:   Partially addressable: 01 02 03 04 05 06 07 
2022-03-21 14:49:04.233 8055-8055/com.lds.asandemo I/com.lds.asandemo:   Heap left redzone:       fa
2022-03-21 14:49:04.234 8055-8055/com.lds.asandemo I/com.lds.asandemo:   Freed heap region:       fd
2022-03-21 14:49:04.234 8055-8055/com.lds.asandemo I/com.lds.asandemo:   Stack left redzone:      f1
2022-03-21 14:49:04.234 8055-8055/com.lds.asandemo I/com.lds.asandemo:   Stack mid redzone:       f2
2022-03-21 14:49:04.234 8055-8055/com.lds.asandemo I/com.lds.asandemo:   Stack right redzone:     f3
2022-03-21 14:49:04.234 8055-8055/com.lds.asandemo I/com.lds.asandemo:   Stack after return:      f5
2022-03-21 14:49:04.234 8055-8055/com.lds.asandemo I/com.lds.asandemo:   Stack use after scope:   f8
2022-03-21 14:49:04.234 8055-8055/com.lds.asandemo I/com.lds.asandemo:   Global redzone:          f9
2022-03-21 14:49:04.234 8055-8055/com.lds.asandemo I/com.lds.asandemo:   Global init order:       f6
2022-03-21 14:49:04.234 8055-8055/com.lds.asandemo I/com.lds.asandemo:   Poisoned by user:        f7
2022-03-21 14:49:04.234 8055-8055/com.lds.asandemo I/com.lds.asandemo:   Container overflow:      fc
2022-03-21 14:49:04.234 8055-8055/com.lds.asandemo I/com.lds.asandemo:   Array cookie:            ac
2022-03-21 14:49:04.234 8055-8055/com.lds.asandemo I/com.lds.asandemo:   Intra object redzone:    bb
2022-03-21 14:49:04.234 8055-8055/com.lds.asandemo I/com.lds.asandemo:   ASan internal:           fe
2022-03-21 14:49:04.234 8055-8055/com.lds.asandemo I/com.lds.asandemo:   Left alloca redzone:     ca
2022-03-21 14:49:04.234 8055-8055/com.lds.asandemo I/com.lds.asandemo:   Right alloca redzone:    cb
2022-03-21 14:49:04.234 8055-8055/com.lds.asandemo I/com.lds.asandemo: ==8055==ABORTING
2022-03-21 14:49:04.234 8055-8055/com.lds.asandemo I/com.lds.asandemo: --------- beginning of crash
2022-03-21 14:49:04.234 8055-8055/com.lds.asandemo A/libc: Fatal signal 6 (SIGABRT), code -6 in tid 8055 (om.lds.asandemo)

```

OUTPUT:

```
==8055==ERROR: AddressSanitizer: heap-use-after-free on address 0x003100000015 at pc 0x007f8bff5c74 bp 0x007fe2614550 sp 0x007fe2614548
READ of size 1 at 0x003100000015 thread T0
    #0 0x7f8bff5c73  (/data/app/com.lds.asandemo-2/lib/arm64/libnative-lib.so asan_sample_use_after_free()  J:/project/android/asan_demo/app/src/main/cpp/asan_sample.h:10)
    #1 0x7f8bff5e67  (/data/app/com.lds.asandemo-2/lib/arm64/libnative-lib.so Java_com_lds_asandemo_MainActivity_stringFromJNI  J:/project/android/asan_demo/app/src/main/cpp/native-lib.cpp:12)
    #2 0x7f72cf57b3  (/data/app/com.lds.asandemo-2/oat/arm64/base.odex+0x4207b3)
0x003100000015 is located 5 bytes inside of 10-byte region [0x003100000010,0x00310000001a)
freed by thread T0 here:
    #0 0x7f71f265a7  (/data/app/com.lds.asandemo-2/lib/arm64/libclang_rt.asan-aarch64-android.so free  /usr/local/google/buildbot/src/android/llvm-toolchain/toolchain/compiler-rt/lib/asan/asan_malloc_linux.cc:68)
    #1 0x7f8bff5c17  (/data/app/com.lds.asandemo-2/lib/arm64/libnative-lib.so asan_sample_use_after_free()  J:/project/android/asan_demo/app/src/main/cpp/asan_sample.h:9)
    #2 0x7f8bff5e67  (/data/app/com.lds.asandemo-2/lib/arm64/libnative-lib.so Java_com_lds_asandemo_MainActivity_stringFromJNI  J:/project/android/asan_demo/app/src/main/cpp/native-lib.cpp:12)
    #3 0x7f72cf57b3  (/data/app/com.lds.asandemo-2/oat/arm64/base.odex+0x4207b3)
    #4 0x7f8d0b7283  (/system/lib64/libart.so+0xdf283)
    #5 0x7f8d26a603  (/system/lib64/libart.so+0x292603)
    #6 0x7f8d2635df  (/system/lib64/libart.so+0x28b5df)
    #7 0x7f8d533be7  (/system/lib64/libart.so+0x55bbe7)
    #8 0x7f8d0a0d17  (/system/lib64/libart.so+0xc8d17)
    #9 0x7f8d23c93f  (/system/lib64/libart.so+0x26493f)
    #10 0x7f8d5250ff  (/system/lib64/libart.so+0x54d0ff)
    #11 0x7f8d0b3caf  (/system/lib64/libart.so+0xdbcaf)
previously allocated by thread T0 here:
    #0 0x7f71f268bf  (/data/app/com.lds.asandemo-2/lib/arm64/libclang_rt.asan-aarch64-android.so __interceptor_malloc  /usr/local/google/buildbot/src/android/llvm-toolchain/toolchain/compiler-rt/lib/asan/asan_malloc_linux.cc:88)
    #1 0x7f8bff5c0b  (/data/app/com.lds.asandemo-2/lib/arm64/libnative-lib.so asan_sample_use_after_free()  J:/project/android/asan_demo/app/src/main/cpp/asan_sample.h:8)
    #2 0x7f8bff5e67  (/data/app/com.lds.asandemo-2/lib/arm64/libnative-lib.so Java_com_lds_asandemo_MainActivity_stringFromJNI  J:/project/android/asan_demo/app/src/main/cpp/native-lib.cpp:12)
    #3 0x7f72cf57b3  (/data/app/com.lds.asandemo-2/oat/arm64/base.odex+0x4207b3)
    #4 0x7f8d0b7283  (/system/lib64/libart.so+0xdf283)
    #5 0x7f8d26a603  (/system/lib64/libart.so+0x292603)
    #6 0x7f8d2635df  (/system/lib64/libart.so+0x28b5df)
    #7 0x7f8d533be7  (/system/lib64/libart.so+0x55bbe7)
    #8 0x7f8d0a0d17  (/system/lib64/libart.so+0xc8d17)
    #9 0x7f8d23c93f  (/system/lib64/libart.so+0x26493f)
    #10 0x7f8d5250ff  (/system/lib64/libart.so+0x54d0ff)
    #11 0x7f8d0b3caf  (/system/lib64/libart.so+0xdbcaf)
SUMMARY: AddressSanitizer: heap-use-after-free (/data/app/com.lds.asandemo-2/lib/arm64/libnative-lib.so+0xc73)
Shadow bytes around the buggy address:
  0x00161fffffb0: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
  0x00161fffffc0: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
  0x00161fffffd0: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
  0x00161fffffe0: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
  0x00161ffffff0: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
=>0x001620000000: fa fa[fd]fd fa fa fa fa fa fa fa fa fa fa fa fa
  0x001620000010: fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa
  0x001620000020: fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa
  0x001620000030: fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa
  0x001620000040: fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa
  0x001620000050: fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa
Shadow byte legend (one shadow byte represents 8 application bytes):
  Addressable:           00
  Partially addressable: 01 02 03 04 05 06 07
  Heap left redzone:       fa
  Freed heap region:       fd
  Stack left redzone:      f1
  Stack mid redzone:       f2
  Stack right redzone:     f3
  Stack after return:      f5
  Stack use after scope:   f8
  Global redzone:          f9
  Global init order:       f6
  Poisoned by user:        f7
  Container overflow:      fc
  Array cookie:            ac
  Intra object redzone:    bb
  ASan internal:           fe
  Left alloca redzone:     ca
  Right alloca redzone:    cb
==8055==ABORTING

Warning: missing symbol file for base.odex 0x4207b3
Warning: missing symbol file for base.odex 0x4207b3
Warning: missing symbol file for libart.so 0xdf283
Warning: missing symbol file for libart.so 0x292603
Warning: missing symbol file for libart.so 0x28b5df
Warning: missing symbol file for libart.so 0x55bbe7
Warning: missing symbol file for libart.so 0xc8d17
Warning: missing symbol file for libart.so 0x26493f
Warning: missing symbol file for libart.so 0x54d0ff
Warning: missing symbol file for libart.so 0xdbcaf
Warning: missing symbol file for base.odex 0x4207b3
Warning: missing symbol file for libart.so 0xdf283
Warning: missing symbol file for libart.so 0x292603
Warning: missing symbol file for libart.so 0x28b5df
Warning: missing symbol file for libart.so 0x55bbe7
Warning: missing symbol file for libart.so 0xc8d17
Warning: missing symbol file for libart.so 0x26493f
Warning: missing symbol file for libart.so 0x54d0ff
Warning: missing symbol file for libart.so 0xdbcaf
```



