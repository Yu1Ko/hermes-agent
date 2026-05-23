import json
import math
from functools import reduce
import argparse

class TranslateMode:
    CLICK        =         1
    UP_AND_DOWN  =         2
    DRAG         =         4
    SET_TEXT     =         8


class Json2Udriver:
    def __init__(self, file_path, save_path, mode, time_ceil=True):
        self.file_path = file_path
        self.save_path = save_path
        self.time_ceil = time_ceil
        self.click = mode & TranslateMode.CLICK
        self.up_and_down = mode & TranslateMode.UP_AND_DOWN
        self.drag = mode & TranslateMode.DRAG
        self.set_text = mode & TranslateMode.SET_TEXT
    
    def get_time_str(self, time):
        if self.time_ceil:
            return str(math.ceil(time))
        return str(round(time, 2))

    def Translate(self):
        with open(file=self.file_path, mode='r', encoding='utf-8') as f:
            res = json.load(f)

            tap_count = 0
            
            data_str = ''

            data_str += 'from u3driver import AltrunUnityDriver\n'
            data_str += 'from u3driver import By\n'
            data_str += 'import time\n\n'

            data_str += 'def AutoRun(udriver):\n'

            tap_count += 1
            data_str += '\t' * tap_count + 'try:\n'

            tap_count += 1

            time = 0
            position_x=0
            position_y=0

            # 遍历并转换每一个记录数据项
            for data_item in res:
                time += data_item['time']

                eventHandler = data_item['eventHandler']

                # 只转换点击事件
                if(self.click and eventHandler.endswith('ClickHandler')):
                    data_str += '\t' * tap_count + 'time.sleep(' + self.get_time_str(time) + ')\n'
                    time = 0
                    ui_names = data_item['ui'].split('/')
                    if len(ui_names) > 1:
                        ui_path = reduce(lambda x,y:x+'//'+y, ui_names)
                        command = '\t' * tap_count + 'udriver.find_object(By.PATH,"'+ui_path+'")'
                        
                        command += '.tap()\n'

                        data_str += command
                elif(self.drag and eventHandler.startswith('IBeginDrag')):
                    # 转换开始拖动记录
                    data_str += '\t' * tap_count + 'time.sleep(' + self.get_time_str(time) + ')\n'
                    time = 0
                    position_x = data_item['position']['x']
                    position_y = data_item['position']['y']

                elif(self.drag and eventHandler.startswith('IEndDrag')):
                    # 转换结束拖动记录
                    end_x = data_item['position']['x']
                    end_y = data_item['position']['y']

                    # 获取屏幕宽高，并计算出实际的屏幕坐标
                    ui_names = data_item['ui'].split('/')
                    if len(ui_names) > 1:
                        ui_path = reduce(lambda x,y:x+'//'+y, ui_names)
                        command = '\t' * tap_count + 'udriver.drag('+str(position_x)+','+str(position_y)+','+str(end_x)+','+str(end_y)+','+self.get_time_str(time)+')\n'
                        data_str += command
                elif(self.set_text and eventHandler.count('TextInput')):
                    data_str += '\t' * tap_count + 'time.sleep(' + self.get_time_str(time) + ')\n'
                    ui_names = data_item['inputField'].split('/')
                    if len(ui_names) > 1:
                        print('转换 set_text')
                        ui_path = reduce(lambda x,y:x+'//'+y, ui_names)
                        command = '\t' * tap_count + 'udriver.find_object(By.PATH,"'+ui_path+'")'
                        command += '.set_text("' + data_item['text'] + '")\n'
                        data_str += command

            
            data_str += '\t' * tap_count + 'print("-" * 10 + "all command succeed" + "-" * 10)\n'

            tap_count -= 1
            data_str += '\t' * tap_count + 'except Exception as e:\n'
            tap_count += 1

            data_str += '\t' * tap_count + 'print(f"{e}")\n'
            data_str += '\t' * tap_count + 'raise e\n\n'

            tap_count -= 1
            
            with open(file=self.save_path,mode="w+",encoding='utf-8') as file:
                file.write(data_str)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('-i', help="input file")
    parser.add_argument('-o', help="output file")
    parser.add_argument('-c', help="click mode")
    parser.add_argument('-st', help="settext mode")
    parser.add_argument('-ud', help="upanddown mode")
    parser.add_argument('-d', help="drag mode")
    args = parser.parse_args()

    file_path = args.i
    save_path = args.o

    click = args.c == '1'
    upanddown = args.ud == '1'
    settext = args.st == '1'
    drag = args.d == '1'

    mode = 0
    if click:
        mode = mode | TranslateMode.CLICK
    if upanddown:
        mode = mode | TranslateMode.UP_AND_DOWN
    if settext:
        mode = mode | TranslateMode.SET_TEXT
    if drag:
        mode = mode | TranslateMode.DRAG

    translater = Json2Udriver(file_path, save_path, mode, False)
    translater.Translate()