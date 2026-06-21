EquipmentEnchant = {}
-- 附魔重复操作流程
local Enchant = {
    'UINodeControl.BtnTriggerByCnt("BtnEmptyTop",1)',
    'UINodeControl.BtnTriggerByCnt("BtnEmptyTop",2)',
    'UINodeControl.BtnTriggerByCnt("BtnEnchant")',
    'UINodeControl.BtnTriggerByCnt("BtnOk")',
}
EquipmentEnchant.Line = 1
EquipmentEnchant.nStartTime = 0
EquipmentEnchant.nNextTime = 8 -- 5秒操作一次
EquipmentEnchant.bFlag = false
EquipmentEnchant.nTimeCount= 0
local bFlag = true

local EnchantItem ={}
EnchantItem.nLine = 1
EnchantItem.nCount = 0 -- 道具总数
function EquipmentEnchant.GetEnchantItemdwID(nEnchantItemLine,dwItemIndex)
    -- 格子的道具数量
    local nItemCount = DataModel.GetItemList(dwItemIndex)[nEnchantItemLine].nStackNum
    -- 格子对应的dwID
    local nItemdwID = DataModel.GetItemList(dwItemIndex)[nEnchantItemLine].dwID
    return nItemCount, nItemdwID
end

local ndwItemIndex = 0 -- 道具id
-- 操作函数
function EquipmentEnchant.FrameUpdate()
    if EquipmentEnchant.nTimeCount > 7200 then
        bFlag = true
    end
    if GetTickCount()-EquipmentEnchant.nStartTime >= EquipmentEnchant.nNextTime*1000 then
        -- 是否在中附魔界面
        if UIMgr.IsViewOpened(VIEW_ID.PanelSystemPrograssBar) then
            return
        end
        if not EquipmentEnchant.bFlag then
            if EquipmentEnchant.Line == 3 then
                -- 写死附魔栏道具
                if EquipmentEnchant.Line == 3 then
                    ndwItemIndex = 71190
                end
                -- 道具是否耗尽
                local nCount,ndwID = EquipmentEnchant.GetEnchantItemdwID(EnchantItem.nLine,ndwItemIndex)
                if nCount == 1  then
                    -- 是否遍历完道具
                    if EnchantItem.nLine == #DataModel.GetItemList(ndwItemIndex)  then
                        -- 添加道具
                        local szGM = "for i=1,50 do player.AddItem(5 ,"..ndwItemIndex..")"
                        SendGMCommand(szGM)
                        EnchantItem.nLine = 1
                    end
                    EnchantItem.nLine  = EnchantItem.nLine + 1
                end
                -- 选中对应道具
                UIMgr.GetViewScript(VIEW_ID.PanelPowerUp).tSubViewScripts[596]:ChoseEnchant(ndwID, ndwItemIndex)
                UIMgr.GetViewScript(VIEW_ID.PanelPowerUp).tSubViewScripts[596]:UpdateInfo()
                EquipmentEnchant.nStartTime = GetTickCount()
                EquipmentEnchant.bFlag = true
                return
            end
        end
        -- 附魔流程
        if EquipmentEnchant.Line == #Enchant+1 then
            EquipmentEnchant.Line = 1
            EquipmentEnchant.bFlag  = false
        end
        SearchPanel.MyExecuteScriptCommand(Enchant[EquipmentEnchant.Line])
        EquipmentEnchant.Line = EquipmentEnchant.Line + 1
        EquipmentEnchant.nTimeCount = EquipmentEnchant.nTimeCount+8
        EquipmentEnchant.nStartTime = GetTickCount()
    end
end


function EquipmentEnchant.Start()
    Timer.AddFrameCycle(EquipmentEnchant,1,function ()
        EquipmentEnchant.FrameUpdate()
    end)
end


--读取tab的内容
RunMap = {}
local list_RunMapCMD = {}
local list_RunMapTime = {}
local tbRunMapData=SearchPanel.LoadRunMapFile(SearchPanel.szCurrentInterfacePath.."RunMap.tab",2)
list_RunMapCMD = tbRunMapData[1]
list_RunMapTime = tbRunMapData[2]
local nCurrentTime = 0
local nNextTime=tonumber(30)
local nCurrentStep=1

function RunMap.FrameUpdate()
    if not SearchPanel.IsFromLoadingEnterGame() then
        return
    end
    if bFlag and GetTickCount()-nCurrentTime>nNextTime*1000 then
        if nCurrentStep==#list_RunMapCMD then
            bFlag=false
        end
        --切图前后置操作
        local szCmd=list_RunMapCMD[nCurrentStep]
        local nTime=tonumber(list_RunMapTime[nCurrentStep])
        AutoTestLog.INFO(szCmd)
        pcall(function ()
            SearchPanel.RunCommand(szCmd)
        end)
        AutoTestLog.INFO(szCmd.."===ok")
        OutputMessage("MSG_SYS",szCmd)
        nNextTime=nTime
        --切图操作
        if string.find(szCmd,"replace") then
            UIMgr.GetViewScript(VIEW_ID.PanelPowerUp):OnSelected(597, false);UIMgr.GetViewScript(VIEW_ID.PanelPowerUp):OnSelected(596, true)
        end
        if string.find(szCmd,"Enchant_start") then
            --启动切图帧更新函数
            EquipmentEnchant.Start()
            bFlag = false
        end
		nCurrentTime=GetTickCount()
        nCurrentStep=nCurrentStep+1
    end
end

Timer.AddFrameCycle(RunMap,1,function ()
    RunMap.FrameUpdate()
end)


return EquipmentEnchant