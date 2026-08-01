# -*- coding: utf-8 -*-
from CaseCommon import *
from BaseToolFunc import *
from io import BytesIO
import numpy as np
from flask import Flask, jsonify, request
from paddleocr import PaddleOCR

#安装部署需要查看飞书文档：https://d7n9vj8ces.feishu.cn/docx/F2tEdxP8joassUx7UZIcOzbZnAc

class CaseDemo(CaseCommon):

    def run_local(self, dic_args):

        # 初始化Flask应用
        app = Flask(__name__)
        # 初始化PaddleOCR模型
        ocr = PaddleOCR(lang="ch", use_gpu=True, use_angle_cls=True)

        # 定义路由和处理函数
        @app.route('/ocr', methods=['POST'])
        def ocrpaddle():
            try:
                # ocr = PaddleOCR(lang="ch")
                # 从HTTP请求中获取图像数据
                image_data = request.get_data()
                if not image_data:
                    return jsonify({'error': 'missing file data'})

                # 解码Base64格式的图片数据，并转换为PIL图像对象
                image = Image.open(BytesIO(base64.b64decode(image_data)))
                # 使用了base64.b64decode()方法和BytesIO()类对Base64编码格式的图片数据进行解码和转换，并最终得到了一个PIL（Python Imaging Library）图像对象。

                # 调用PaddleOCR进行图像识别
                result = ocr.ocr(np.array(image))

                # 返回识别结果
                return jsonify({'result': result})

            except Exception as e:
                print(e)
                return jsonify({'error': str(e)})

        app.run(host='0.0.0.0', port=8765, debug=False, threaded=True)

if __name__ == '__main__':
    obj = CaseDemo()
    obj.run_from_IQB()