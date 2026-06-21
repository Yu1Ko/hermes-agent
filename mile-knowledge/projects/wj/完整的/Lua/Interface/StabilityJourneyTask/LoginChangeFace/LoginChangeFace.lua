LoginMgr.Log("AutoLogin","AutoLogin imported")
AutoLogin={}
LoginChangeFace ={}
local PresetFace = {} 
local PresetFaceSecond = {}
LoginChangeFace.bSwitch =true
AutoLogin.bSwitch=true
local nStepTime = 5
--[[]]
-- LoginRole --
--角色创建
-- 捏脸预设界面
local FacePresetsLeft={}    -- 左边
local nFacePresetsLeftCount=0   -- 预设捏脸
local tbFacePresetsLeft    -- tog表
local bFacePresetsLeft = false
local nFacePresetsLeftLine=1   -- 捏脸预设界面（右）行数
local nFacePresetsLeftStartTime = 0
local nFacePresetsLeftNextTime = 3

local FacePresetsRight={}   -- 右边
local FacePresetsRightTog={}
FacePresetsRightTog.nStartTime = 0
FacePresetsRightTog.nNextTime = 10
local nFacePresetsRightCount=0   -- 预设捏脸右边按钮总数
local bFacePresetsRight = true
local tbFacePresetsRight    -- tog表
local nTogCount = 0	-- 面板总数
local nTogLine = 1
local nFacePresetsRightLine=1   -- 捏脸预设界面（右）行数
local nFacePresetsRightStartTime = 0
local nFacePresetsRightNextTime = 5

-- 细节调整
DetailPanel={}	-- 总开关
DetailPanelLeft={}	-- 细节调整左边
DetailPanelRight={}	-- 细节调整右边


-- 解决起名失效的问题
local InputName = {}
local nNameNextTime = 10  --等待10秒后没有反应重新点击起名和确认
local nNameStartTime = 0
function InputName.FrameUpdate()
    if GetTickCount() - nNameStartTime > nNameNextTime*1000 then
        local bInputName = UIMgr.IsViewOpened(VIEW_ID.PanelCreateName_Login)
        if bInputName then
			-- 写死为段式 成男
			local nRoletypeNum = 1
			local nSchooltypeNum = 20
			if nRoletypeNum == 3 then
				nRoletypeNum = 6
			end
			if nRoletypeNum == 4 then
				nRoletypeNum = 5
			end
			--  5个汉字
			local szNewName
			local szName1 = RandomName(nRoletypeNum)
			local szName2 = RandomName(nRoletypeNum)
		
			if #szName1 == 12 then
				local subStr = string.sub(szName2, 1, 3)
				szNewName = szName1..subStr
			elseif #szName1 == 9 then
				local subStr = string.sub(szName2, 1, 6)
				szNewName = szName1..subStr
			end
			LoginMgr.GetModule(LoginModule.LOGIN_ROLE).CreateRole(nRoletypeNum,nSchooltypeNum,szNewName)
        else
            -- 结束帧函数
            LoginChangeFace.bSwitch = false
		    Timer.DelAllTimer(InputName)
			UINodeControl.BtnTrigger("BtnNext","WidgetAnchorRightBottom")
        end
        nNameStartTime = GetTickCount()
    end
end

-- 预设界面
local nTypePreseCount = 0	-- 预设总目录
local nTypePreseLine = 1	-- 当前预设目录
local nSecondListCount = 1	-- 整体目录总数
local nSecondListLine = 1	-- 当前遍历身体目录
local bPresetFaceFirst = false
local bPresetFaceStart = false
local bPresetFaceSecond = false
local PresetFaceEnd = {}
function GetTabTypeCount()
	local nTabTypeCount = UINodeControl.GetToggroup("TogGroupTabType")
    nTypePreseCount = #nTabTypeCount
end

function GetDefaultListCount()
	local nDefaultListCount = UINodeControl.GetToggroup("ScrollViewDefaultList")
    nSecondListCount = #nDefaultListCount
end

function GetFaceListCount()
	local nFaceListCount = UINodeControl.GetToggroup("ScrollViewFaceList")
    nSecondListCount = #nFaceListCount
end

function GetBodyListCount()
	local nBodyCount = UINodeControl.GetToggroup("ScrollViewBodyList")
    nSecondListCount = #nBodyCount
end

function PresetFaceSecond.FrameUpdate()
	if not bPresetFaceSecond then
		if nTypePreseLine == 1 then
			GetDefaultListCount()
		elseif nTypePreseLine == 2 then
			GetFaceListCount()
		elseif nTypePreseLine == 3 then
			GetBodyListCount()
		end
		bPresetFaceSecond = true
	end
	if nSecondListLine ~= nSecondListCount+1 then
		if nSecondListLine ~= 1 then
			if nTypePreseLine == 1 then
				UINodeControl.TogTriggerByIndex("ScrollViewDefaultList",nSecondListLine)
			elseif nTypePreseLine == 2 then
				UINodeControl.TogTriggerByIndex("ScrollViewFaceList",nSecondListLine)
			elseif nTypePreseLine == 3 then
				UINodeControl.TogTriggerByIndex("ScrollViewBodyList",nSecondListLine)
			end
		end
		nSecondListLine = nSecondListLine + 1
	else
		nSecondListLine = 1
		bPresetFaceSecond= false
		nTypePreseLine = nTypePreseLine + 1
		Timer.DelAllTimer(PresetFaceSecond)
		bPresetFaceFirst = false
	end
end


function PresetFace.FrameUpdate()
	if not bPresetFaceStart then
		GetTabTypeCount()
		bPresetFaceStart = true
		return
	end
	if nTypePreseLine == nTypePreseCount+1 then
		-- 结束帧函数
		-- Timer.AddFrameCycle(FacePresetsLeft,1,function ()
		-- 	FacePresetsLeft.FrameUpdate()
		-- end)
		Timer.DelAllTimer(PresetFace)
		UINodeControl.BtnTriggerByLable("BtnNext","下一步")
		Timer.AddCycle(PresetFaceEnd,3,function ()
			if UIMgr.IsViewOpened(VIEW_ID.PanelBuildFace_Step2) then
				Timer.DelAllTimer(PresetFaceEnd)
				--进入了捏脸界面 结束更新函数 启动捏脸
				Timer.AddFrameCycle(FacePresetsLeft,1,function ()
					FacePresetsLeft.FrameUpdate()
				end)
			end
		end)
	end
	if not bPresetFaceFirst then
		UINodeControl.TogTriggerByIndex("TogGroupTabType",nTypePreseLine)
		bPresetFaceFirst = true
		Timer.AddCycle(PresetFaceSecond,4,function ()
			PresetFaceSecond.FrameUpdate()
		end)
	end
end



local function EnterBuildFace()
	--[[]]
	-- --进入了捏脸界面 结束更新函数
	-- Timer.Add(AutoLogin,nStepTime*4,function ()
	-- 	Timer.AddFrameCycle(FacePresetsLeft,1,function ()
	-- 	 	FacePresetsLeft.FrameUpdate()
	-- 	end)
	-- end)
	--[[]]
	Timer.Add(AutoLogin,nStepTime,function ()
		UINodeControl.BtnTriggerByLable("BtnConfirm","下一步")
		LoginMgr.Log("AutoLogin","BtnConfirm--下一步")
	end)
	Timer.Add(AutoLogin,nStepTime*3,function ()
		Timer.AddCycle(PresetFace,2,function ()
			PresetFace.FrameUpdate()
		end)
	end)
	-- 防止捏脸出现问题 出现问题把这部分打开
	-- Timer.Add(AutoLogin,nStepTime*3,function ()
	-- 	UINodeControl.BtnTrigger("BtnNext")
	-- 	LoginMgr.Log("AutoLogin","BtnNext1--下一步")
	-- end)
	
	-- Timer.Add(AutoLogin,nStepTime*4,function ()
	-- 	UINodeControl.BtnTrigger("BtnNext","WidgetAnchorRightButtom")
	-- 	LoginMgr.Log("AutoLogin","BtnNext2--完成创建")
	-- end)

	-- Timer.Add(AutoLogin,nStepTime*5,function ()
	-- 	UINodeControl.BtnTrigger("BtnRandom","WidgetInfo01")
	-- 	LoginMgr.Log("AutoLogin","BtnRandom--随机名称")
	-- end)

	-- Timer.Add(AutoLogin,nStepTime*7,function ()
	-- 	UINodeControl.BtnTrigger("BtnConfirm","WidgetButton")
	-- 	LoginMgr.Log("AutoLogin","BtnConfirm--确认")
    --     nNameStartTime = GetTickCount()
    --     if UIMgr.IsViewOpened(VIEW_ID.PanelInputName) then
    --         Timer.AddFrameCycle(InputName,1,function ()
    --             InputName.FrameUpdate()
    --         end)
    --     else
    --         LoginChangeFace.bSwitch = false
    --         UINodeControl.BtnTrigger("BtnNext","WidgetAnchorRightBottom")
    --     end
	-- end)
end

local function EnterFace()
	Timer.Add(AutoLogin,nStepTime*5,function ()
		UINodeControl.BtnTrigger("BtnNext","WidgetAnchorRightButtom")
		LoginMgr.Log("AutoLogin","BtnNext2--下一步")
	end)

	Timer.Add(AutoLogin,nStepTime*6,function ()
		UINodeControl.BtnTrigger("BtnRandom","WidgetInfo01")
		LoginMgr.Log("AutoLogin","BtnRandom--随机名称")
	end)

	Timer.Add(AutoLogin,nStepTime*7,function ()
		UINodeControl.BtnTrigger("BtnConfirm","WidgetButton")
		LoginMgr.Log("AutoLogin","BtnConfirm--确认")
        nNameStartTime = GetTickCount()
        if UIMgr.IsViewOpened(VIEW_ID.PanelCreateName_Login) then
            Timer.AddFrameCycle(InputName,1,function ()
                InputName.FrameUpdate()
            end)
        else
            LoginChangeFace.bSwitch = false
            UINodeControl.BtnTrigger("BtnNext","WidgetAnchorRightBottom")
        end
	end)
end
--print(UINodeControl.GetToggroup("ScrollViewDefaultList"))
-- 捏脸预设面板（左）
-- 初始化预设列表数据
function FacePresetsLeft.Initialization()
    tbFacePresetsLeft = UINodeControl.GetToggroup("TogGroupDefaultList")
    nFacePresetsLeftCount = #tbFacePresetsLeft
end

function FacePresetsLeft.FrameUpdate()
    if GetTickCount() - nFacePresetsLeftStartTime >= nFacePresetsLeftNextTime*1000 then
        --结束捏脸预设面板右左边边遍历 进行右边面板遍历
		if not bFacePresetsLeft then
			FacePresetsLeft.Initialization()
			bFacePresetsLeft= true
			nFacePresetsLeftStartTime = GetTickCount()
			return
		end
        if nFacePresetsLeftLine == nFacePresetsLeftCount + 1 then
            -- 结束帧函数
			Timer.DelAllTimer(FacePresetsLeft)
			Timer.AddFrameCycle(FacePresetsRight,1,function ()
				FacePresetsRight.FrameUpdate()
			end)
        end
        UINodeControl.TogTriggerByIndex("TogGroupDefaultList",nFacePresetsLeftLine)
        nFacePresetsLeftLine = nFacePresetsLeftLine + 1
        nFacePresetsLeftStartTime = GetTickCount()
    end
end

-- 捏脸预设面板（右）
-- 初始化预设列表数据
function FacePresetsRight.Initialization()
    tbFacePresetsRight = UINodeControl.GetToggroup("LayoutRightTop")
    nFacePresetsRightCount = #tbFacePresetsRight
end
-- 初始化左侧面板
function FacePresetsRight.LayoutList()
    tbFacePresetsRight = #UINodeControl.GetToggroup("LayoutList1")
    nTogCount = tbFacePresetsRight
end


function FacePresetsRight.FrameUpdate()
	if bFacePresetsRight and GetTickCount() - nFacePresetsRightStartTime >= nFacePresetsRightNextTime*1000 then
		if nFacePresetsRightCount ==0  then
			FacePresetsRight.Initialization()
			return
		end
		-- 这部分暂时写死 节点中有个表情被屏蔽掉了
		if nFacePresetsRightLine ==  3 then
			Timer.DelAllTimer(FacePresetsRight)
			DetailPanel.Start()
		end
		UINodeControl.TogTriggerByIndex("LayoutRightTop",nFacePresetsRightLine)
		nFacePresetsRightStartTime = GetTickCount()
		bFacePresetsRight = false
		FacePresetsRightTog.nStartTime = GetTickCount()
		Timer.AddFrameCycle(FacePresetsRightTog,1,function ()
			FacePresetsRightTog.FrameUpdate()
		end)
	end
end

local bTogInitialization = false	--初始化
-- 暂时写死 选中天气试穿表情这部分
function FacePresetsRightTog.FrameUpdate()
	if GetTickCount() - FacePresetsRightTog.nStartTime >= FacePresetsRightTog.nNextTime*1000 then
		if not bTogInitialization then
			FacePresetsRight.LayoutList()
			bTogInitialization = true
			FacePresetsRightTog.nStartTime = GetTickCount()
			return
		end
		if nTogLine == nTogCount+1  then
			nFacePresetsRightLine = nFacePresetsRightLine + 1
			bTogInitialization = false
			bFacePresetsRight = true
			nTogLine = 1
			nFacePresetsRightStartTime = GetTickCount()
			Timer.DelAllTimer(FacePresetsRightTog)
			return
		end
		UINodeControl.TogTriggerByIndex("LayoutList1",nTogLine)
		nTogLine = nTogLine + 1
		FacePresetsRightTog.nStartTime = GetTickCount()
	end
end



--细节调整
DetailPanelLeft.nStartTime=0
DetailPanelLeft.nNextTime=3
DetailPanelRight.nStartTime=0
DetailPanelRight.nNextTime=5
DetailPanelLeft.TogGroupPageCount=0
DetailPanelLeft.TogGroupClass1Count=0
DetailPanelLeft.TogGroupClass2Count=0
DetailPanelLeft.TogGroupPageLine=1
DetailPanelLeft.TogGroupClass1Line=1
DetailPanelLeft.TogGroupClass2Line=1
DetailPanelLeft.TogGroupClass3Line = 1	-- 三级目录
local nSpecialCount
-- 第一目录
function GetTogGroupPageCount()
	local nCount = #UINodeControl.GetToggroup("TogGroupPage")
	DetailPanelLeft.TogGroupPageCount=nCount
	return DetailPanelLeft.TogGroupPageCount
end

-- 第二目录
function GetTogGroupClass1Count()
	if DetailPanelLeft.TogGroupPageLine ~= 3 then
		local nCount = #UINodeControl.GetToggroup("ScrollViewTab2")
		DetailPanelLeft.TogGroupClass1Count=nCount
		return DetailPanelLeft.TogGroupClass1Count
	else
		DetailPanelLeft.TogGroupClass1Count=0
		return DetailPanelLeft.TogGroupClass1Count
	end
end
-- 第三目录 特殊操作有些目录没有第三目录
function GetTogGroupClass2Count()
	if DetailPanelLeft.TogGroupPageLine == 3 or DetailPanelLeft.TogGroupPageLine == 4 then
		DetailPanelLeft.TogGroupClass2Count= 0
		return DetailPanelLeft.TogGroupClass2Count
	else
		local nCount = #UINodeControl.GetToggroup("TogGroupClass1")
		-- 特殊处理
		if DetailPanelLeft.TogGroupClass2Line ~= 1 then
			nSpecialCount = nCount-DetailPanelLeft.TogGroupClass2Line
		else
			nSpecialCount = nCount
		end
		nSpecialCount = nCount
		DetailPanelLeft.TogGroupClass2Count= nSpecialCount
		return DetailPanelLeft.TogGroupClass2Count
	end
end

-- 分为三种面板
local nTogLine = 2
local bDetailPanelRight = false
-- 封装处理函数
function DetailPanelTogTrigger()
	if DetailPanelLeft.TogGroupPageLine == 1 then
		if DetailPanelLeft.TogGroupClass2Line == 1 and DetailPanelLeft.TogGroupClass2Line == 1 then
			UINodeControl.TogTriggerByIndex("TogGroupDefault",nTogLine)
		else
			UINodeControl.BtnTriggerByCnt("ButtonAdd",2)
		end
	elseif DetailPanelLeft.TogGroupPageLine ==2 then
		if DetailPanelLeft.TogGroupClass1Line == 5 and DetailPanelLeft.TogGroupClass3Line == 2 or DetailPanelLeft.TogGroupClass1Line == 5 and DetailPanelLeft.TogGroupClass3Line == 3 then
			UINodeControl.TogTriggerByIndex("TogGroupDetailAdjust",nTogLine)
		elseif DetailPanelLeft.TogGroupClass1Line == 7 and DetailPanelLeft.TogGroupClass3Line == 2 then
			UINodeControl.TogTriggerByIndex("TogGroupDetailAdjust",nTogLine)
		elseif DetailPanelLeft.TogGroupClass1Line == 9 and DetailPanelLeft.TogGroupClass3Line == 1 then
			UINodeControl.TogTriggerByIndex("TogGroupDetailAdjust",nTogLine)
		else
			UINodeControl.TogTriggerByIndex("ScrollViewDetailAdjust",nTogLine)
		end
	elseif DetailPanelLeft.TogGroupPageLine ==3 then
		UINodeControl.TogTriggerByIndex("ScrollViewDefault",nTogLine)
	elseif DetailPanelLeft.TogGroupPageLine == 4 then
		if DetailPanelLeft.TogGroupClass2Line == 1 then
			UINodeControl.TogTriggerByIndex("ScrollViewDefault",8)
		else
			UINodeControl.BtnTriggerByCnt("ButtonAdd",5)
		end
	end
end

function GetDetailPanelTogCount()
	local nDetailPanelTogCount = 0
	if DetailPanelLeft.TogGroupPageLine == 1 then
		if DetailPanelLeft.TogGroupClass2Line == 1 and DetailPanelLeft.TogGroupClass2Line == 1 then
			nDetailPanelTogCount = #UINodeControl.GetToggroup("TogGroupDefault")
		end
	elseif DetailPanelLeft.TogGroupPageLine ==2 then
		if DetailPanelLeft.TogGroupClass1Line == 5 and DetailPanelLeft.TogGroupClass3Line == 2 or DetailPanelLeft.TogGroupClass1Line == 5 and DetailPanelLeft.TogGroupClass3Line == 3 then
			nDetailPanelTogCount = #UINodeControl.GetToggroup("TogGroupDetailAdjust")
		elseif DetailPanelLeft.TogGroupClass1Line == 7 and DetailPanelLeft.TogGroupClass3Line == 2 then
			nDetailPanelTogCount = #UINodeControl.GetToggroup("TogGroupDetailAdjust")
		elseif DetailPanelLeft.TogGroupClass1Line == 9 and DetailPanelLeft.TogGroupClass3Line == 1 then
			nDetailPanelTogCount = #UINodeControl.GetToggroup("TogGroupDetailAdjust")
		else
			nDetailPanelTogCount = #UINodeControl.GetToggroup("ScrollViewDetailAdjust")
		end
	elseif DetailPanelLeft.TogGroupPageLine ==3 then
		nDetailPanelTogCount = #UINodeControl.GetToggroup("ScrollViewDefault")
	elseif DetailPanelLeft.TogGroupPageLine == 4 then
		if DetailPanelLeft.TogGroupClass2Line == 1 then
			nDetailPanelTogCount = #UINodeControl.GetToggroup("ScrollViewDefault")
		end
	end
	return nDetailPanelTogCount
end
local bInitial = false
-- 本处使用很多的特殊操作 因为在切换面板时 左边面板和右边的面板对应不上 分为两部分操作
function DetailPanelLeft.FrameUpdate()
	if not bDetailPanelRight and GetTickCount() - DetailPanelLeft.nStartTime >= DetailPanelLeft.nNextTime*1000 then
		if not bInitial then
			-- 初始化点击一次
			UINodeControl.TogTriggerByIndex("TogGroupPage",1)
			DetailPanelLeft.nStartTime= GetTickCount()
			bInitial = true
			return
		end
		if DetailPanelLeft.TogGroupClass3Line ~= GetTogGroupClass2Count()+1 then
			if GetTogGroupClass2Count() == 0 then
				DetailPanelLeft.TogGroupClass3Line = GetTogGroupClass2Count()+1
				return
			end
			if DetailPanelLeft.TogGroupClass3Line ~= 1  then
				UINodeControl.TogTriggerByIndex("TogGroupClass1",DetailPanelLeft.TogGroupClass2Line)
			end
			-- DetailPanelLeft.TogGroupClass2Line = DetailPanelLeft.TogGroupClass2Line + 1
			-- DetailPanelLeft.TogGroupClass3Line = DetailPanelLeft.TogGroupClass3Line + 1
		elseif DetailPanelLeft.TogGroupClass1Line ~= GetTogGroupClass1Count()-1 then
			if GetTogGroupClass1Count() == 0 then
				DetailPanelLeft.TogGroupClass1Line = GetTogGroupClass1Count()-1
				return
			end
			DetailPanelLeft.TogGroupClass1Line = DetailPanelLeft.TogGroupClass1Line + 2
			if DetailPanelLeft.TogGroupPageLine == 2 and DetailPanelLeft.TogGroupClass1Line == 9 then
				UINodeControl.TogTriggerByIndex("ScrollViewTab2",10)
			else
				UINodeControl.TogTriggerByIndex("ScrollViewTab2",DetailPanelLeft.TogGroupClass1Line)
			end
			DetailPanelLeft.TogGroupClass3Line = 1
		elseif DetailPanelLeft.TogGroupPageLine ~= GetTogGroupPageCount()-1 then
			DetailPanelLeft.TogGroupPageLine = DetailPanelLeft.TogGroupPageLine + 1
			UINodeControl.TogTriggerByIndex("TogGroupPage",DetailPanelLeft.TogGroupPageLine)
			DetailPanelLeft.TogGroupClass2Line = 1
			DetailPanelLeft.TogGroupClass3Line = 1
			DetailPanelLeft.TogGroupClass1Line = 1
		else
			Timer.DelAllTimer(DetailPanelLeft)
			EnterFace()
		end
		-- DetailPanelLeft.nStartTime= GetTickCount()
		DetailPanelRight.nStartTime = GetTickCount()
		-- 右边面板遍历
		bDetailPanelRight = true
		Timer.AddFrameCycle(DetailPanelRight,1,function ()
			DetailPanelRight.FrameUpdate()
		end)
	end
end


local tbDetailPanelRightTog = {2}	-- 需要遍历的参数 默认会遍历最后一个参数
local nDetailPanelRightTogLine = 1
function DetailPanelRight.FrameUpdate()
	if GetTickCount() - DetailPanelRight.nStartTime >= DetailPanelRight.nNextTime*1000 then
		if nDetailPanelRightTogLine == #tbDetailPanelRightTog+2 or GetDetailPanelTogCount() == 0 then
			DetailPanelLeft.nStartTime= GetTickCount()
			bDetailPanelRight = false
			nDetailPanelRightTogLine= 1
			DetailPanelLeft.TogGroupClass2Line = DetailPanelLeft.TogGroupClass2Line + 1
			DetailPanelLeft.TogGroupClass3Line = DetailPanelLeft.TogGroupClass3Line + 1
			Timer.DelAllTimer(DetailPanelRight)
		end
		if nDetailPanelRightTogLine == #tbDetailPanelRightTog+1 then
			nTogLine = GetDetailPanelTogCount()
		else
			nTogLine = tbDetailPanelRightTog[nDetailPanelRightTogLine]
		end
		-- 执行
		DetailPanelTogTrigger()
		DetailPanelRight.nStartTime = GetTickCount()
		nDetailPanelRightTogLine = nDetailPanelRightTogLine + 1
	end
end

DetailPanel.bSwitch = true
function DetailPanel.Start()
	if not DetailPanel.bSwitch then
		return
	end
	Timer.AddFrameCycle(DetailPanelLeft,1,function ()
		DetailPanelLeft.FrameUpdate()
	end)
end



LoginChangeFaceStart = {}
LoginChangeFaceStart.bSwitch = false
LoginBuildFace = {}
function LoginChangeFaceStart.FrameUpdate()
    if not LoginChangeFace.bSwitch then
        Timer.DelAllTimer(LoginChangeFaceStart)
		StabilityController.bFlag = true
    end
    if LoginChangeFaceStart.bSwitch then
        if LoginChangeFace.bSwitch then
			EnterBuildFace()
			LoginChangeFaceStart.bSwitch = false
        end
    end
end

Timer.AddCycle(LoginChangeFaceStart,1,function ()
    LoginChangeFaceStart.FrameUpdate()
end)



return LoginChangeFace