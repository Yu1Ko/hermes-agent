import json
import math


if __name__ == "__main__":

    file_path = 'test.txt'

    with open(file=file_path, mode='r', encoding='utf-8') as f:
        res = json.load(f)
        
        data_str = 'import time\n'
        data_str += 'from poco.drivers.unity3d import UnityPoco\n'
        data_str += 'poco = UnityPoco()\n\n'
        
        time = 0
        for data_item in res:
            time += data_item['time']

            # 只转换点击事件
            if(data_item['eventHandler'].endswith('ClickHandler')):
                data_str += 'time.sleep(' + str(math.ceil(time)) + ')\n'
                time = 0
                ui_names = data_item['ui'].split('/')
                if len(ui_names) > 1:
                    click_command = 'poco("'+ui_names[1]+'")'
                    for ui in ui_names[2:]:
                        click_command+='.child("'+ui+'")'
                    
                    click_command+='.click()\n'

                    data_str+=click_command
        
        with open(file=file_path.replace('.txt','.py'),mode="w+",encoding='utf-8') as file:
            file.write(data_str)



    