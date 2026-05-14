from win32com.client import Dispatch
from ctypes import *
from BaseToolFunc import *
import pythoncom
import ctypes
import cv2

class TextInfo(object):
    def __init__(self, x, y, text=""):
        self.x = x
        self.y = y
        self.text = text


class Op:

    def __init__(self):
        pythoncom.CoInitialize()
        self.op=Dispatch("op.opsoft")
        self.initLogger(logging.getLogger(str(os.getpid())))


    def initLogger(self,log):
        try:
            self.log = log
        except Exception:
            info = traceback.format_exc()
            print(info)
            raise Exception('initLogger ERROR!!')

    def get_screen_region(self):
        width = win32api.GetSystemMetrics(0) # 屏幕宽度
        height = win32api.GetSystemMetrics(1) # 屏幕高度
        print(0,0,width,height)
        return (0,0,width,height) # 左上角(0,0)到右下角(width,height)

    # 获取用于识别的图片样本路径
    def get_image_samples_path(self, pic_name, imageSamplesFolder):
        if not isinstance(pic_name, str):
            raise TypeError("pic_name 必须是字符串类型")

        pic_name = pic_name.strip()
        if not pic_name:
            raise ValueError("pic_name不能为空字符串或仅包含空白字符")  

        if not isinstance(imageSamplesFolder, str):
            raise TypeError("imageSamplesFolder必须是字符串类型")

        safe_filename = os.path.basename(pic_name)
        #full_path = os.path.normpath(os.path.join(imageSamplesFolder, safe_filename)) + ".png"
        full_path = os.path.normpath(os.path.join(imageSamplesFolder, safe_filename))
        return full_path


    # 获取文本坐标
    def get_text_coordinate(self,button_text,region=None,color_format="000000-000000",sim=0.8):
        if region is None:
            region = self.get_screen_region()

        if not isinstance(region, tuple) or len(region) != 4:
            raise ValueError("region必须是一个四元素元组")

        top_left_x, top_left_y, lower_right_x, lower_right_y = region

        # 检查区域坐标的合理性
        if (not all(isinstance(x, int) for x in region)) or not (top_left_x >= 0 and top_left_y >= 0 and lower_right_x > top_left_x and lower_right_y > top_left_y):
            raise ValueError("区域坐标不合法")
        
        op_ret = self.op.OcrEx(top_left_x,top_left_y,lower_right_x,lower_right_y,color_format,sim)
        """
        在 OCR 识别结果中查找目标文本的坐标。

        :param op_ret: OCR 识别结果字符串，格式为 "x1,y1,text1|x2,y2,text2|..."
        :param target_text: 需要查找的目标文本
        :return: 如果找到目标文本，返回其坐标 (x, y)；否则返回 None
        """
        # 分割识别结果
        results = op_ret.split("|")

        # 遍历识别结果
        for result in results:
            # 分割每个结果的坐标和文本
            parts = result.split(",") # 避免如果text携带逗号的情况
            if len(parts) >= 3 and parts[0].strip().isdigit() and parts[1].strip().isdigit():# 确保至少有三个字段（x 和 y 和 text）
                x = int(parts[0])  # 第一个字段是 x
                y = int(parts[1])  # 第二个字段是 y
                text = ",".join(parts[2:])  # 剩余字段拼接为文本
                # 判断文本是否与目标文本一致
                self.log.info(text)
                print('---------------')
                print(text)
                if button_text.lower() in text.lower():
                    self.log.info(f'I found {text}')
                    textInfo = TextInfo(x,y,text)
                    return textInfo  # 文本信息

        # 如果没有找到匹配的文本，返回 None
        return None
        

    def wait_text_coordinate(self,button_text,region=None,color_format="000000-000000",sim=0.8,timeout=25):
        if region is None:
            region = self.get_screen_region()
        time_start = time.time()
        while 1:
            if time.time() - time_start > timeout:
                raise Exception(f'wait_text timeout: {button_text}')
            textInfo = self.get_text_coordinate(button_text,region,color_format,sim)
            if textInfo:
                return textInfo
            time.sleep(1)

    
    # pic_name要识别到的图像路径,delta_color偏色(图像默认000000),sim相似度(默认0.8),dir方向(默认0从左到右,从上到下),region选取范围
    # 获取图像坐标左上角
    def get_image_coordinate(self, pic_name, region=None, delta_color="000000", sim=0.8, dir=0, imageSamplesFolder="ImageSamples"):
        if region is None:
            region = self.get_screen_region()
        
        if not isinstance(region, tuple) or len(region) != 4:
            raise ValueError("region必须是一个四元素元组")

        top_left_x, top_left_y, lower_right_x, lower_right_y = region

        # 检查区域坐标的合理性
        if (not all(isinstance(x, int) for x in region)) or not (top_left_x >= 0 and top_left_y >= 0 and lower_right_x > top_left_x and lower_right_y > top_left_y):
            raise ValueError("区域坐标不合法")

        try:
            # 获取完整的图像路径
            #image_path = self.get_image_samples_path(pic_name, imageSamplesFolder)
            image_path=pic_name

            if not os.path.isfile(image_path):
                raise FileNotFoundError(f"未找到图片文件: {image_path}")

            # 调用FindPic方法进行搜索
            r, x, y = self.op.FindPic(top_left_x, top_left_y,
                                      lower_right_x, lower_right_y,
                                      image_path, delta_color, sim, dir)

            if r >= 0 and x >= 0 and y >= 0:
                textInfo = TextInfo(x, y)
                return textInfo

        except Exception as e:
            self.log.error(f"获取图像坐标失败：{str(e)}")
            raise

        return None

    # pic_name要识别到的图像路径,delta_color偏色(图像默认000000),sim相似度(默认0.8),dir方向(默认0从左到右,从上到下),region选取范围
    # 获取图像坐标中心
    def get_image_coordinate_center(self, pic_name, region=None, delta_color="000000", sim=0.8, dir=0,
                             imageSamplesFolder="ImageSamples"):
        if region is None:
            region = self.get_screen_region()

        if not isinstance(region, tuple) or len(region) != 4:
            raise ValueError("region必须是一个四元素元组")

        top_left_x, top_left_y, lower_right_x, lower_right_y = region

        # 检查区域坐标的合理性
        if (not all(isinstance(x, int) for x in region)) or not (
                top_left_x >= 0 and top_left_y >= 0 and lower_right_x > top_left_x and lower_right_y > top_left_y):
            raise ValueError("区域坐标不合法")

        try:
            # 获取完整的图像路径
            # image_path = self.get_image_samples_path(pic_name, imageSamplesFolder)
            image_path = pic_name
            print(image_path)
            print(pic_name)

            if not os.path.isfile(image_path):
                raise FileNotFoundError(f"未找到图片文件: {image_path}")

            # 调用FindPic方法进行搜索
            r, x, y = self.op.FindPic(top_left_x, top_left_y,
                                      lower_right_x, lower_right_y,
                                      image_path, delta_color, sim, dir)

            if r >= 0 and x >= 0 and y >= 0:
                # 读取图片
                img = cv2.imread(pic_name)
                # 获取宽、高
                height, width = img.shape[:2]
                # 计算中心点坐标
                center_x = int(width / 2)
                center_y = int(height / 2)
                textInfo = TextInfo(x+center_x, y+center_y)
                return textInfo

        except Exception as e:
            self.log.error(f"获取图像坐标失败：{str(e)}")
            raise

        return None


    def wait_image_coordinate(self,pic_name,region,delta_color="000000",sim=0.8,dir=0,timeout = 10,imageSamplesFolder = "ImageSamples"):
        # 截图识别
        time_start = time.time()
        while 1:
            if time.time() - time_start > timeout:
                raise Exception(f'wait_image timeout: {pic_name}')
            textInfo = self.get_image_coordinate(pic_name,region,delta_color,sim,dir,imageSamplesFolder) # 避免没有找到返回的是None的情况
            if textInfo:
                return textInfo
            time.sleep(1)


# if __name__ == '__main__':
#     op = Op()
#     op.get_image(pic_name="VISA",region=(270,160,1170,750))
#     op.get_text_coordinate(button_text="Pay Now",region=(270,160,1170,750),color_format="feffff-000000")