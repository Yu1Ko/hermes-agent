import os
import threading
import time
import traceback
import ftplib
from datetime import datetime
from CaseCommon import CaseCommon
from ftplib import FTP
from BaseToolFunc import filecontrol_copyFileOrFolder
import shutil


class PackageManage(CaseCommon):
    def __init__(self):
        super().__init__()
        # ftp相关配置
        self.ftp_host = "10.11.80.122"
        self.ftp_port = 21
        self.ftp_user = "ftp1"
        self.ftp_pass = "ftp+123"
        self.ftp_folder = ["xgame-head-ipa", "xgame-qa-ipa", "xgame-exp-apk", "xgame-qa-apk", "xgame-mb-apk",
                           'xgame-ts-ipa']

        # 共享相关配置
        #self.file_share_package_path = r"\\10.11.85.148\FileShare-144-44\FTP-back"  # 共享包目录
        self.file_share_package_path = r"\\10.11.144.44\FileShare\FTP-back"  # 共享包目录
        self.file_share_save_day = 8  # 共享文件包保存天数

        self.push_immediate = True  # 是否立即推送包到共享
        self.push_time = 6  # 每日推送共享包时间 24小时制

    def _init_ftp(self):
        ftp = FTP()
        ftp.connect(self.ftp_host, self.ftp_port)
        ftp.login(self.ftp_user, self.ftp_pass)

        def keepAlive():
            try:
                while True:
                    ftp.voidcmd("NOOP")
                    time.sleep(60)
            except ftplib.all_errors:
                pass

        t = threading.Thread(target=keepAlive, daemon=True)
        t.start()
        return ftp

    def _get_ftp_packages(self, path, ftp=None):
        """获取ftp目录下的包，并按文件修改日期降序排序，即新的在前面"""
        if not ftp:
            ftp = self._init_ftp()

        def _get_ftp_file_info(file_path):
            return {
                'path': file_path,
                'time': ftp.sendcmd('MDTM ' + file_path)[4:]
            }

        packages_info = [_get_ftp_file_info(os.path.join(path, file_name)) for file_name in ftp.nlst(path) if
                         os.path.splitext(file_name)[1] in ['.ipa', '.apk']]
        packages_info.sort(key=lambda x: x['time'], reverse=True)
        return [dic_info['path'] for dic_info in packages_info]

    def _check_dic_args(self, args):
        ftp_arr = [arr_name for arr_name in dir(self) if "ftp_" in arr_name]
        for ftp_name in ftp_arr:
            setattr(self, ftp_name, args.get(ftp_name, getattr(self, ftp_name)))
        self.push_immediate = args.get('push_immediate', self.push_immediate)
        self.push_time = args.get('push_time', self.push_time)
        self.file_share_package_path = args.get('file_share_package_path', self.file_share_package_path)
        self.file_share_save_day = args.get('file_share_save_day', self.file_share_save_day)
        pass

    def thread_ftp_package_manage(self):
        """
        ftp包管理线程

            - 保持ftp上 ftp_folder目录只有一个最新的包
        """
        ftp = self._init_ftp()
        self.log.info(f"ftp包管理线程启动")
        while True:
            try:
                for folder_name in self.ftp_folder:
                    package_paths = self._get_ftp_packages(folder_name, ftp)
                    if len(package_paths) > 1:
                        # 如果目录下有多个包
                        for del_package_path in package_paths[1:]:
                            # 此处是fpt要删除的包
                            self.log.info(f"删除fpt旧包：{del_package_path}")
                            ftp.delete(del_package_path)
            except:
                self.log.error(f"ftp包管理线程异常：\n{traceback.format_exc()}")
            finally:
                # 默认10分钟检测一次
                time.sleep(10 * 60)
        pass

    def push_ftpfile_to_fileshare(self, ftp_file_path, file_share_path, ftp=None):
        """
        将ftp中的文件推送至共享
        """
        if not ftp:
            ftp = self._init_ftp()
        local_path = os.path.basename(ftp_file_path)
        with open(local_path, 'wb') as local_file:
            # 从远程服务器下载文件到本地
            self.log.info(f"正在下载ftp文件:{file_share_path}至本地:{local_path}")
            ftp.retrbinary('RETR ' + ftp_file_path, local_file.write, 1024)
            local_file.close()
        self.log.info(f"下载完成，开始推送至共享:{file_share_path}")
        filecontrol_copyFileOrFolder(local_path, file_share_path)
        self.log.info(f"推送完成，删除本地文件:{local_path}")
        os.remove(local_path)
        pass

    def push_fileshare(self, ftp=None):
        """
        推送ftp self.ftp_folder 这些路径最新的包到共享中
        """
        try:
            if not ftp:
                ftp = self._init_ftp()
            for folder_name in self.ftp_folder:
                package_paths = self._get_ftp_packages(folder_name, ftp)
                if len(package_paths) > 0:
                    push_package_path = package_paths[0]
                    today = datetime.now().strftime('%Y-%m-%d')
                    fileshare_path = os.path.join(self.file_share_package_path, folder_name, today)
                    if not os.path.exists(fileshare_path):
                        self.log.info(f"创建共享目录:{fileshare_path}")
                        os.makedirs(fileshare_path)
                    if os.path.basename(push_package_path) not in os.listdir(fileshare_path):
                        # 如果ftp最新的包没有推送过
                        for filename in os.listdir(fileshare_path):  # 清空文件夹
                            file_path = os.path.join(fileshare_path, filename)
                            if os.path.isfile(file_path):
                                self.log.info(f"删除共享目录中的包:{file_path}")
                                os.remove(file_path)
                        self.log.info(f"开始推送ftp文件:{push_package_path}至共享:{fileshare_path}")
                        self.push_ftpfile_to_fileshare(push_package_path, fileshare_path, ftp)
        except:
            self.log.error(f"推送包至共享时异常：\n{traceback.format_exc()}")
        pass

    def thread_ftp_push_fileshare(self):
        """
        共享推送包线程

            - 线循环检测是否到了推送包的日期
            - 如果到了日期，则将推送共享中没有的包
        """
        self.log.info(f"共享推送包线程启动")
        ftp = self._init_ftp()
        while True:
            try:
                if datetime.now().hour == self.push_time:
                    self.push_fileshare(ftp)
            except:
                self.log.error(f"推送包异常：\n{traceback.format_exc()}")
            finally:
                time.sleep(10*60)
        pass

    def thread_file_share_package_manage(self):
        self.log.info(f"共享文件夹包管理线程启动")
        while True:
            try:
                today = datetime.now()
                for folder in self.ftp_folder:
                    folder_path = os.path.join(self.file_share_package_path, folder)
                    for item in os.listdir(folder_path):
                        item_path = os.path.join(folder_path, item)
                        # 获取文件夹的时间
                        folder_date = datetime.strptime(item, '%Y-%m-%d')
                        time_diff = today - folder_date  # 时间对比
                        if time_diff.days >= self.file_share_save_day:
                            shutil.rmtree(item_path)
            except:
                self.log.error(f"共享文件夹包管理线程异常：\n{traceback.format_exc()}")
            finally:
                # 默认30分钟检测一次
                time.sleep(30*60)

    def run_local(self, dic_args):
        self._check_dic_args(dic_args)
        t1 = threading.Thread(target=self.thread_ftp_package_manage, daemon=True)

        t1.start()
        if self.push_immediate:
            self.log.info(f"立即推送ftp包至共享")
            self.push_fileshare()
        t1 = threading.Thread(target=self.thread_ftp_push_fileshare, daemon=True)
        t1.start()

        t1 = threading.Thread(target=self.thread_file_share_package_manage, daemon=True)
        t1.start()
        t1.join()
        pass


if __name__ == '__main__':
    o = PackageManage()
    # o.run_local({"file_share_package_path": "FileShareTest", "file_share_save_day": 1})
    o.run_from_IQB()
