from opt_file_parser import OptFileParser
import xlsxwriter


class OptDataReport(OptFileParser):
    def __init__(self, input_path):
        OptFileParser.__init__(self, input_path)
        self.function_information = {}
        self.main_function_information = {}
        self.dict_main_function = {
            'CPU Frame': '帧耗时',
            'KEventQueueMgr::HandleEventQueue': '处理表现逻辑事件',
            'KGameWorldHandler::UpdateBackend': '更新世界的后台数据',
            'UI::AsyncTask::FetchResult': '处理异步任务',
            'KG3D_Engine::FrameMove': 'KG3D_Engine',
            'KG3D_ASyncHLODLoader::_HandleLoadResult': '处理LOD更新',
            'KG3D_SceneObjectContainer::Update': '物件更新',
            'KG3D_FlexibleBodyScene::FetchResult': '柔体更新',
            'KG3D_SceneView::_UpdateVisibleList': '可见性',
            'KG3D_SceneView::_UpdateCommonRenderData_Optimise': 'RenderData',
            'KG3D_SceneView::_Render_SunCamera_VisibleObject_To_ShadowTexture_CSMVer2': '阴影',
            'KG3D_SceneView::RenderGBuffers': 'GBuffer',
            'KG3D_SceneView::RenderOITTransparent': 'OIT',
            'KG3D_SceneView::_Render_MainCamera_OITOpaqueObject': 'OIT',
            'KG3D_SceneView::renderMainCamera_BlendObject': 'Blend',
            'KG3D_SceneView::renderMainCamera_Cloaking': 'Cloak',
            'KG3D_SceneView::renderMainCamera_ParticleSystem': '粒子系统',
            'KG3D_SceneView::renderMainCamera_PSSShakeWaveTexture': 'PSS',
            'KG3D_2DScene::Render': '2D渲染',
            'KG3D_Window::Present': 'present',
        }
        super()

    # Override: get the data for xlsx report need
    def read_events(self):
        """ DataResponse::EventFrame = 1 """
        if 1 != self.read_data_response(False)[2]:
            return
        self.record(f"{'-' * 5} DumpEvents {'-' * 5}")
        size = self.read_data_response()[1]
        # begin
        begin_pointer = self.pointer
        # ScopeData.header
        board_number = self.read_uint32()
        thread_number = self.read_uint32()
        fiber_number = self.read_uint32()
        event_time_begin = self.read_uint64()
        event_time_end = self.read_uint64()
        frame_type = self.read_uint32()
        # ScopeData.categories
        categories = []
        categories_count = self.read_uint32()
        for i in range(categories_count):
            categories.append(self.read_event_data())
        # ScopeData.events
        events = []
        events_count = self.read_uint32()
        for i in range(events_count):
            events.append(self.read_event_data()[0:3])
        # end
        self.check_end(begin_pointer, size)
        # print
        self.record(
            f"boardNumber={board_number} threadNumber={thread_number} fiberNumber={fiber_number:0X} frameType={frame_type:0X}")
        self.record(f"event_time = [{event_time_begin}, {event_time_end}]")
        self.record(f"categories_count = {categories_count}")
        self.record(f"events_count = {events_count}")
        self.record(">>>  time_start   time_finish   desc_index")
        # if this event belongs to main thread, then record it
        if self.threads[thread_number] != self.main_thread_id:
            return
        temp = []
        for i in range(events_count):
            events[i][2] = self.event_descs[events[i][2]].split('(')[0]  # 将event_desc的索引转换为字符串描述
            self.record(f"[{i}] {events[i][0]} {events[i][1]} {events[i][2]}")
            temp.append([events[i][0], events[i][1], events[i][2]])

            self.get_main_function_information(events[i])
            self.get_all_function_information(events[i])

        self.frame_events.append(temp)

    '''
    参考 https://xlsxwriter.readthedocs.io/working_with_tables.html
    data = [
        ['Apples', 10000, 5000, 8000, 6000],
        ['Pears',   2000, 3000, 4000, 5000],
        ['Bananas', 6000, 6000, 6500, 6000],
        ['Oranges',  500,  300,  200,  700],

    ]
    worksheet.add_table('B3:F7', {'data': data})'''
    def get_all_function_table(self):
        self.function_information['FunctionTable'] = []
        for key in self.function_information.keys():
            if key == 'FunctionTable':
                continue
            length = len(self.frame_events)
            TotalFunctionTime = sum(self.function_information[key]['FunctionTime'])
            self.function_information[key]['AvgFunctionTime'] = TotalFunctionTime / length / 10000
            self.function_information['FunctionTable'].append([key,
                                                               round(self.function_information[key]
                                                                     ['AvgFunctionTime'], 3)])

    def get_main_function_table(self):
        self.main_function_information['FunctionTable'] = []
        for key in self.main_function_information.keys():
            if key == 'FunctionTable':
                continue
            length = len(self.frame_events)
            TotalFunctionTime = sum(self.main_function_information[key]['FunctionTime'])
            self.main_function_information[key]['AvgFunctionTime'] = TotalFunctionTime / length / 10000
            self.main_function_information['FunctionTable'].append([self.dict_main_function[key], key,
                                                                    round(self.main_function_information[key]
                                                                    ['AvgFunctionTime'], 3)])

    # 设置需要分析的函数字典 {函数名：函数解释}
    def set_function_dict(self, dict_function=None):
        if dict_function is not None:
            self.dict_main_function = dict_function

    def get_main_function_information(self, event):
        if event[2] not in self.dict_main_function:
            return

        # event[1] - event[0] : time_start -  time_finish; time/10000 = n(ms)
        if event[2] not in self.main_function_information:
            self.main_function_information[event[2]] = {}
            self.main_function_information[event[2]]['AvgFunctionTime'] = 0
            self.main_function_information[event[2]]['FunctionTime'] = []
            self.main_function_information[event[2]]['FunctionTime'].append(int(event[1] - event[0]))
        else:
            self.main_function_information[event[2]]['FunctionTime'].append(int(event[1] - event[0]))
        pass

    def write_main_function(self, workbook):
        worksheet = workbook.add_worksheet('Main')
        self.get_main_function_table()
        CellRange = 'A%d:C%d' % (1, len(self.main_function_information['FunctionTable']))
        DataFormat = {'data': self.main_function_information['FunctionTable'],
                      'columns': [{'header': '模块'},
                                  {'header': '函数'},
                                  {'header': '耗时（ms）'},
                                  ]}
        worksheet.add_table(CellRange, DataFormat)

    def get_all_function_information(self, event):
        # event[1] - event[0] : time_start -  time_finish; time/10000 = n(ms)
        if event[2] not in self.function_information:
            self.function_information[event[2]] = {}
            self.function_information[event[2]]['AvgFunctionTime'] = 0
            self.function_information[event[2]]['FunctionTime'] = []
            self.function_information[event[2]]['FunctionTime'].append(int(event[1] - event[0]))
        else:
            self.function_information[event[2]]['FunctionTime'].append(int(event[1] - event[0]))

    def write_all_function(self, workbook):
        worksheet = workbook.add_worksheet('All')
        self.get_all_function_table()
        CellRange = 'A%d:B%d' % (1, len(self.function_information['FunctionTable']))
        DataFormat = {'data': self.function_information['FunctionTable'],
                      'columns': [{'header': '函数'},
                                  {'header': '耗时（ms）'},
                                  ]}
        worksheet.add_table(CellRange, DataFormat)

    def write_function_time_to_xlsx(self):
        workbook = xlsxwriter.Workbook(self.input_path[0:-3] + "xlsx")
        self.write_main_function(workbook)
        self.write_all_function(workbook)
        workbook.close()

    def run(self):
        self.read_opt_content()
        self.parse()
        self.write_function_time_to_xlsx()


if __name__ == '__main__':
    # xx = OptDataReport(r"F://主城.opt")
    xx = OptDataReport(r"D:/trunk/client/opt数据/1060_成都(2022-10-24.16-35-07).opt")
    xx.run()
