import argparse
import os

key_list = ['M', 'N', 'A', 'R', 'b', 'Z', 'K', 'S', 'r', 'D', 'p', 'c', 'V', 'U', 't', 'A', 'K', 'K', 'q',
            'L', 'm',
            'K', 't', 'e', '0', '6', 'f', '9', 'D', 'j', '0', 'J', 'l', 'Y', 'T', 'Z', 'M', 'N', 'h', 'E',
            'G', '4',
            'q', 'M', 'D', 'Y', 'K', 'M', '0', 'P', 'C', 'H', 'j', '6', '2', 'f', 'S', 'R', 'o', '6', '0',
            'k', 'C']


def decode(log_text):
    encode_str = ''
    index = 0
    for i in log_text:
        encode_str += chr(ord(i) ^ ord(key_list[index % len(key_list)]))
    index += 1
    return encode_str


if __name__ == "__main__":
    argparser = argparse.ArgumentParser()
    argparser.add_argument("-f", "--file", help="Decode file.")
    args = argparser.parse_args()

    if args.file:
        decode_file = os.path.normpath(args.file)
        assert os.path.isfile(decode_file), "输入参数不是一个文件"
        with open(decode_file, "r", encoding="utf-8") as f:
            for line in f.readlines():
                print(decode(line))
    else:
        argparser.print_help()

    #python perfeye_log_decode.py -f log.txt > log_decode.txt