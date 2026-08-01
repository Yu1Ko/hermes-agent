import argparse
import os
import sys
import re
import sys
import subprocess
import signal
import traceback

CUR_DIR = os.path.dirname(os.path.abspath(__file__))
#ADDR2LINE_PATH = os.path.join(CUR_DIR, "arm-linux-androideabi-addr2line.exe")
ADDR2LINE_PATH = os.path.join(CUR_DIR, "aarch64-linux-android-addr2line.exe")
ADB_PATH = "adb"
g_symbols_cache = {}
g_strip_index = 0
g_running = False
g_in_asan_log_block = False
# e.g.: ==5047==ERROR: AddressSanitizer: heap-use-after-free on address 0x003100000015 at pc 0x00781b225c84 bp 0x007ff90d9c20 sp 0x007ff90d9c18
g_start_pattern = re.compile(r"==(\d+)==ERROR: AddressSanitizer")
# e.g.: ==5047==ABORTING
g_end_pattern = re.compile(r"==(\d+)==ABORTING")
# e.g.: #0 0x78198dd5a7  (/data/app/~~qCP1AoL0TUAHwGJZfcnkxg==/com.lds.asandemo-zIE077T2cyCX5Ufyy5pK5Q==/lib/arm64/libclang_rt.asan-aarch64-android.so+0x9f5a7)
#g_stack_pattern = re.compile(r"#(\d+)\W+(0x[0-9a-fA-F]+)\W+\(([^+]+)\+(0x[0-9a-fA-F]+)\)")
g_stack_pattern = re.compile(r".*#(\d+\d+)\W+pc\W+([0-9a-fA-F]+)(.*.so)\W+.*")
g_modules = {}


def addr2line(symbol_file, address):
    global g_symbols_cache
    cache_key = symbol_file + "+" + address
    if cache_key in g_symbols_cache:
        return g_symbols_cache[cache_key]

    cmd = (ADDR2LINE_PATH, "-e", symbol_file, "-C", "-f", address)
    output = subprocess.check_output(cmd)
    if output:
        name = output.decode("utf-8").strip()
        name = name.replace("\n", " ")
        name = name.replace("\r", " ")
        g_symbols_cache[cache_key] = name
        return name
    return "NOT FOUND SYMBOL"


def find_symbol_file(symbols_dirs, libname):
    for symbols_dir in symbols_dirs:
        symbol_file = os.path.join(symbols_dir, libname)
        if os.path.exists(symbol_file):
            return symbol_file
    return None


def process_log_line(line, symbols_dirs):
    global g_in_asan_log_block, g_strip_index

    g_in_asan_log_block = True
    m = g_start_pattern.search(line)
    '''if m:
        g_strip_index = line.index(m[0])
        line = line[g_strip_index:].rstrip()
        g_in_asan_log_block = True
        print("\n================================== ASAN REPORT BEGIN ==============================================")
        print(line)
        return
    elif g_end_pattern.search(line):
        line = line[g_strip_index:].rstrip()
        g_in_asan_log_block = False
        print(line)
        print("================================== ASAN REPORT END ==============================================\n")
        return
    '''
    
    line = line.rstrip()
    if g_strip_index:
        line = line[g_strip_index:].rstrip()
    if not line:
        print("")
        return

    if g_in_asan_log_block:
        m = g_stack_pattern.search(line)
        if m:
            num = m[1] # e.g.: 0
            prefix = line[:line.index('#'+num)]
            abs_addr = m[2]  # e.g.: 0x78198dd5a7
            libpath = m[3]  # e.g.: /data/app/~~qCP1AoL0TUAHwGJZfcnkxg==/com.lds.asandemo-zIE077T2cyCX5Ufyy5pK5Q==/lib/arm64/libnative-lib.so

            
            libname = os.path.basename(libpath)  # e.g.: libnative-lib.so
            g_modules[libpath] = libpath
            symbol_file = find_symbol_file(symbols_dirs, libname)
            if symbol_file:
                symbol_name = addr2line(symbol_file, abs_addr)
            else:
                symbol_name = abs_addr
                
            print("{prefix}#{num} {symbol_name} {libname}".format(prefix=prefix, num=num, symbol_name=symbol_name, libname=libname))
        else:
            print(line)


def symbolize(log_file, symbols_dirs, strip_log_prefix = True):
    with open(log_file) as f:
        for line in f:
            process_log_line(line, symbols_dirs)
    print("MODULES:")
    for key, value in g_modules.items():
        print("    " + key)

def start_logcat(symbols_dirs):
    global g_running
    signal.signal(signal.SIGINT, stop_logcat)
    signal.signal(signal.SIGTERM, stop_logcat)
    #subprocess.Popen(ADB_PATH + " logcat -c", shell=True)
    cmd = ADB_PATH + " logcat -v threadtime"  # 设置logcat输出格式为 <datetime> <pid> <tid> <priority> <tag>: <message>
    logcat_process = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
    print("start logcat, press `Ctrl+C` to exit")
    g_running = True
    while g_running:
        raw_line = ""
        try:
            raw_line = logcat_process.stdout.readline()
            line = raw_line.decode("utf-8").strip()
            #print(line)
        except UnicodeDecodeError:
            #traceback.print_exc()
            print("[warning] 无法解析原始日志: %s" % raw_line)
            continue
        process_log_line(line, symbols_dirs)
    logcat_process.kill()
    g_running = False


def stop_logcat():
    global running
    running = False


def main():
    if not os.path.exists(ADDR2LINE_PATH):
        print("%s is not exists!" % ADDR2LINE_PATH)
        sys.exit(-1)

    arg_parser = argparse.ArgumentParser()
    arg_parser.add_argument("--input", "-i", help="input log file")
    arg_parser.add_argument("--symbols_dirs", "-s", nargs='+', help="symbols dir")
    arg_parser.add_argument("--adb", "-a", action='store_true', help="use `adb logcat` as input")
    args = arg_parser.parse_args()

    symbols_dirs = args.symbols_dirs
    if symbols_dirs:
        for symbols_dir in symbols_dirs:
            if not os.path.exists(symbols_dir):
                print("%s symbols dir is not exists!" % symbols_dir)
                sys.exit(-1)

    if not args.adb:  # `file` as input
        log_file = args.input
        if not log_file:
            print("missing `--input` arg")
            sys.exit(-1)
        if not os.path.exists(log_file):
            print("%s input file is not exists!" % log_file)
            sys.exit(-1)
        if not symbols_dirs:
            symbols_dirs = [ os.path.dirname(log_file) ]  # default: use dir of log file as symbols_dir
        symbolize(log_file, symbols_dirs)
    else:  # `adb logcat` as input
        start_logcat(symbols_dirs)


if __name__ == '__main__':
    main()

