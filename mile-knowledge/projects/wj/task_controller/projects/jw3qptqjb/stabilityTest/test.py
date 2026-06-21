# -*- coding: utf-8 -*-
import sys
import os
import re
import psutil
from datetime import time
from collections import deque


def find_numeric_log_files(directory):
    """
    查找指定目录下所有数字文件名的.log文件

    参数:
        directory (str): 要搜索的目录路径

    返回:
        list: 包含所有匹配文件完整路径的列表
    """
    numeric_log_files = []

    # 编译正则表达式，匹配纯数字文件名后跟.log扩展名
    pattern = re.compile(r'^\d+\.log$', re.IGNORECASE)

    for root, dirs, files in os.walk(directory):
        for file in files:
            # 检查当前目录的子文件夹中是否包含目标文件夹
            if pattern.match(file):
                # 构建完整文件路径
                full_path = os.path.join(root, file)
                numeric_log_files.append(full_path)

    return numeric_log_files

def find_new_file(find_dir_path):
    """查找目录下最新的文件夹"""
    dir_lists = os.listdir(find_dir_path)
    dir_lists.sort(key=lambda fn: os.path.getmtime(find_dir_path + r"/" + fn) if not os.path.isdir(
        find_dir_path + r"/" + fn) else 0)
    new_dir_path = os.path.join(find_dir_path, dir_lists[-1])
    '''查找目录下最新的log文件'''
    new_dir = os.listdir(new_dir_path)
    new_dir.sort(key=lambda fn: os.path.getmtime(new_dir_path + r"/" + fn))
    new_log_path = os.path.join(new_dir_path, new_dir[-1])
    return new_log_path


def filtration_log(file_path):
    with open(file_path, 'r') as f:
        file_lines = f.readlines()
    for line in file_lines:
        match = re.search(r'Validation Error(.*)', line) or re.search(r'Validation Warning(.*)', line)
        if match:
            return True
    return False

def get_filepath_without_extension_str(filepath):
    """
    使用字符串处理获取文件路径但不包含后缀

    参数:
    filepath: 文件路径或文件名

    返回:
    不带后缀的文件名
    """
    # 获取基础文件名（去除路径）
    # if "/" in filepath:
    #     base_name = filepath.split("/")[-1]
    # elif "\\" in filepath:  # 处理Windows路径
    #     base_name = filepath.split("\\")[-1]
    # else:
    #     base_name = filepath

    # 查找最后一个点号的位置
    dot_index = filepath.rfind(".")

    # 如果没有点号或点号在开头（如隐藏文件），返回整个文件名
    if dot_index <= 0:
        return filepath

    # 返回点号之前的部分
    return filepath[:dot_index]

def filter_lines_by_keywords(input_lines, keywords):
    """
    过滤文本行，只保留包含特定关键字的行

    参数:
    input_lines: 输入的行列表
    keywords: 要过滤的关键字列表

    返回:
    包含指定关键字的行列表
    """
    # 确保keywords是列表形式
    if isinstance(keywords, str):
        keywords = [keywords]

    # 过滤出包含任一关键字的行
    filtered_lines = [
        line for line in input_lines
        if any(keyword in line for keyword in keywords)
    ]

    return filtered_lines

def filter_lines_by_not_have_keywords(input_lines, keywords):
    """
    过滤文本行，只保留包含特定关键字的行

    参数:
    input_lines: 输入的行列表
    keywords: 要过滤的关键字列表

    返回:
    包含指定关键字的行列表
    """
    # 确保keywords是列表形式
    if isinstance(keywords, str):
        keywords = [keywords]

    # 过滤出包含任一关键字的行
    filtered_lines = [
        line for line in input_lines
        if not any(keyword in line for keyword in keywords)
    ]

    return filtered_lines

def filter_vk_layer_log_and_save(vk_layer_log_path):
    vk_layer_message_to_filter = ["Vulkan Loader", "KB", "VULKANHOOK", "AK Error:"]
    filtered_lines_vk_layer_log_path = get_filepath_without_extension_str(vk_layer_log_path) + "_filter.log"
    file_lines = []
    filtered_vk_layer_lines = []
    with open(vk_layer_log_path, 'r') as f:
        file_lines = f.readlines()
    filtered_vk_layer_lines = filter_lines_by_not_have_keywords(file_lines, vk_layer_message_to_filter)
    with open(filtered_lines_vk_layer_log_path, 'w') as f:
        f.writelines(filtered_vk_layer_lines)

    return True


def fix_timestamp_alignment(log_file_path, output_file_path=None):
    """
    修复时间戳错位的日志文件

    参数:
        log_file_path (str): 输入日志文件路径
        output_file_path (str): 输出文件路径，如果为None则创建新文件
    """
    # 读取日志文件
    with open(log_file_path, 'r', encoding='gbk') as f:
        lines = f.readlines()

    # 定义正则表达式匹配时间戳
    timestamp_pattern = re.compile(r'^(\d{8}-\d{6},\d{3,}):')

    # 存储时间戳队列和内容队列
    timestamps = deque()
    contents = deque()

    # 分离时间戳和内容
    for line in lines:
        line = line.strip()
        if not line:
            continue

        # 检查是否包含时间戳
        timestamp_match = timestamp_pattern.match(line)
        if timestamp_match:
            # 提取时间戳和剩余内容
            timestamp = timestamp_match.group(1)
            content = line[len(timestamp) + 1:].strip()

            # 添加到队列
            timestamps.append(timestamp)
            if content:
                contents.append(content)
        else:
            # 没有时间戳的行，直接作为内容
            contents.append(line)

    # 修复时间戳错位
    fixed_lines = []

    # 处理第一个内容（没有对应的时间戳）
    if contents and not timestamps:
        fixed_lines.append(contents.popleft())

    # 将时间戳与下一个内容配对
    while timestamps and contents:
        timestamp = timestamps.popleft()
        content = contents.popleft()
        fixed_lines.append(f"{timestamp}:{content}")

    # 处理剩余的时间戳（没有对应的内容）
    while timestamps:
        fixed_lines.append(f"{timestamps.popleft()}:")

    # 处理剩余的内容（没有对应的时间戳）
    while contents:
        fixed_lines.append(contents.popleft())

    # 确定输出路径
    if output_file_path is None:
        base_name, ext = os.path.splitext(log_file_path)
        output_file_path = f"{base_name}_fixed{ext}"

    # 写入修复后的日志
    with open(output_file_path, 'w', encoding='utf-8') as f:
        f.write("\n".join(fixed_lines))

    print(f"日志修复完成，输出文件: {output_file_path}")
    return output_file_path

if __name__ == '__main__':
    vk_log_folder_path = r"F:\Xgame\NVIDIA GeForce GTX 750 Ti\20250829\XGame-楚州定点-VK验证层检查"
    vk_log_files =  find_numeric_log_files(vk_log_folder_path)
    for vk_log_file in vk_log_files:
        filter_vk_layer_log_and_save(vk_log_file)
        #fix_timestamp_alignment(vk_log_file,vk_log_file)
