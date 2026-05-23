HomelandBulidHotkey = HomelandBulidHotkey or {className = "HomelandBulidHotkey"}
local self = HomelandBulidHotkey
local tbKeycode2Img = {
    ["<"]       = "<img src='UIAtlas2_Home_HomeLandBuilding_VKHotKeys_Img_KeyJianKHLeft' width='26' height='27'/>",
    [">"]       = "<img src='UIAtlas2_Home_HomeLandBuilding_VKHotKeys_Img_KeyJianKHRight' width='26' height='27'/>",
    ["1"]       = "<img src='UIAtlas2_Home_HomeLandBuilding_VKHotKeys_Img_Key1' width='26' height='27'/>",
    ["6"]       = "<img src='UIAtlas2_Home_HomeLandBuilding_VKHotKeys_Img_Key6' width='26' height='27'/>",
    ["A"]       = "<img src='UIAtlas2_Home_HomeLandBuilding_VKHotKeys_Img_KeyA' width='26' height='27'/>",
    ["C"]       = "<img src='UIAtlas2_Home_HomeLandBuilding_VKHotKeys_Img_KeyC' width='26' height='27'/>",
    ["D"]       = "<img src='UIAtlas2_Home_HomeLandBuilding_VKHotKeys_Img_KeyD' width='26' height='27'/>",
    ["E"]       = "<img src='UIAtlas2_Home_HomeLandBuilding_VKHotKeys_Img_KeyE' width='26' height='27'/>",
    ["L"]       = "<img src='UIAtlas2_Home_HomeLandBuilding_VKHotKeys_Img_KeyL' width='26' height='27'/>",
    ["O"]       = "<img src='UIAtlas2_Home_HomeLandBuilding_VKHotKeys_Img_KeyO' width='26' height='27'/>",
    ["Q"]       = "<img src='UIAtlas2_Home_HomeLandBuilding_VKHotKeys_Img_KeyQ' width='26' height='27'/>",
    ["R"]       = "<img src='UIAtlas2_Home_HomeLandBuilding_VKHotKeys_Img_KeyR' width='26' height='27'/>",
    ["S"]       = "<img src='UIAtlas2_Home_HomeLandBuilding_VKHotKeys_Img_KeyS' width='26' height='27'/>",
    ["U"]       = "<img src='UIAtlas2_Home_HomeLandBuilding_VKHotKeys_Img_KeyU' width='26' height='27'/>",
    ["W"]       = "<img src='UIAtlas2_Home_HomeLandBuilding_VKHotKeys_Img_KeyW' width='26' height='27'/>",
    ["X"]       = "<img src='UIAtlas2_Home_HomeLandBuilding_VKHotKeys_Img_KeyX' width='26' height='27'/>",
    ["Y"]       = "<img src='UIAtlas2_Home_HomeLandBuilding_VKHotKeys_Img_KeyY' width='26' height='27'/>",
    ["Z"]       = "<img src='UIAtlas2_Home_HomeLandBuilding_VKHotKeys_Img_KeyZ' width='26' height='27'/>",
    ["V"]       = "<img src='UIAtlas2_Home_HomeLandBuilding_VKHotKeys_Img_KeyV' width='26' height='27'/>",
    ["F1"]      = "<img src='UIAtlas2_Home_HomeLandBuilding_VKHotKeys_Img_KeyF1' width='48' height='27'/>",
    ["F2"]      = "<img src='UIAtlas2_Home_HomeLandBuilding_VKHotKeys_Img_KeyF2' width='48' height='27'/>",
    ["F3"]      = "<img src='UIAtlas2_Home_HomeLandBuilding_VKHotKeys_Img_KeyF3' width='48' height='27'/>",
    ["F4"]      = "<img src='UIAtlas2_Home_HomeLandBuilding_VKHotKeys_Img_KeyF4' width='48' height='27'/>",
    ["F5"]      = "<img src='UIAtlas2_Home_HomeLandBuilding_VKHotKeys_Img_KeyF5' width='48' height='27'/>",
    ["F6"]      = "<img src='UIAtlas2_Home_HomeLandBuilding_VKHotKeys_Img_KeyF6' width='48' height='27'/>",
    ["LMB"]     = "<img src='UIAtlas2_Home_HomeLandBuilding_VKHotKeys_Img_MouseLeftClick' width='26' height='27'/>",
    ["LMB_HM"]  = "<img src='UIAtlas2_Home_HomeLandBuilding_VKHotKeys_Img_MouseLeftHoldMove' width='26' height='27'/>",
    ["LMB_DBL"] = "<img src='UIAtlas2_Home_HomeLandBuilding_VKHotKeys_Img_MouseLeftHold' width='26' height='27'/>",
    ["MMB_HM"]  = "<img src='UIAtlas2_Home_HomeLandBuilding_VKHotKeys_Img_MouseMiddleHoldMove' width='26' height='27'/>",
    ["MMB"]     = "<img src='UIAtlas2_Home_HomeLandBuilding_VKHotKeys_Img_MouseMiddleScroll' width='26' height='27'/>",
    ["RMB"]     = "<img src='UIAtlas2_Home_HomeLandBuilding_VKHotKeys_Img_MouseRightClick' width='26' height='27'/>",
    ["RMB_HM"]  = "<img src='UIAtlas2_Home_HomeLandBuilding_VKHotKeys_Img_MouseRightHoldMove' width='26' height='27'/>",
    ["BKT_L"]   = "<img src='UIAtlas2_Home_HomeLandBuilding_VKHotKeys_Img_KeyFangKHLeft' width='26' height='27'/>",
    ["BKT_R"]   = "<img src='UIAtlas2_Home_HomeLandBuilding_VKHotKeys_Img_KeyFangKHRight' width='26' height='27'/>",
    ["CTRL"]    = "<img src='UIAtlas2_Home_HomeLandBuilding_VKHotKeys_Img_KeyCtrl' width='48' height='27'/>",
    ["DEL"]     = "<img src='UIAtlas2_Home_HomeLandBuilding_VKHotKeys_Img_KeyDel' width='48' height='27'/>",
    ["ALT"]     = "<img src='UIAtlas2_Home_HomeLandBuilding_VKHotKeys_Img_KeyAlt' width='48' height='27'/>",
    ["ESC"]     = "<img src='UIAtlas2_Home_HomeLandBuilding_VKHotKeys_Img_KeyEsc' width='48' height='27'/>",
}

local tbBulidHotkeyList = {
    {
        szName = "拉近拉远",
        szHotkey = "[MMB]"
    },
    {
        szName = "直上直下",
        szHotkey = "[Q][E]"
    },
    {
        szName = "平移镜头",
        szHotkey = "[W][A][S][D]/[MMB_HM]"
    },
    {
        szName = "旋转镜头",
        szHotkey = "[<][>]"
    },
    {
        szName = "自由转向",
        szHotkey = "[RMB_HM]"
    },
    {
        szName = "便捷视角",
        szHotkey = "[F6]"
    },
    {
        szName = "拿起物品",
        szHotkey = "[LMB_DBL]/[V]"
    },
    {
        szName = "取消拿起",
        szHotkey = "[ESC]/[RMB]"
    },
    {
        szName = "旋转物品",
        szHotkey = "[Z][C]/[X]"
    },
    {
        szName = "撤销",
        szHotkey = "[CTRL]+[Z]"
    },
    {
        szName = "重做",
        szHotkey = "[CTRL]+[Y]"
    },
    {
        szName = "保存",
        szHotkey = "[CTRL]+[S]"
    },
    {
        szName = "回收",
        szHotkey = "[DEL]"
    },
    {
        szName = "摆放位置",
        szHotkey = "[F5]"
    },
    -- {
    --     szName = "环绕观察",
    --     szHotkey = "[F5]+[RMB_HM]"
    -- },   -- 端游已废弃
    {
        szName = "选中物品",
        szHotkey = "[LMB]"
    },
    {
        szName = "多选",
        szHotkey = "[LMB_HM]/[CTRL]+[LMB]"
    },
    {
        szName = "复制",
        szHotkey = "[CTRL]+[C]"
    },
    {
        szName = "翻页",
        szHotkey = "[BKT_L][BKT_R]"
    },
    {
        szName = "帮助界面",
        szHotkey = "[F1]"
    },
    {
        szName = "室内/室外镜头",
        szHotkey = "[F2]"
    },
    {
        szName = "显示网格",
        szHotkey = "[F3]"
    },
    {
        szName = "网格对齐",
        szHotkey = "[F4]"
    },
    {
        szName = "全部选择",
        szHotkey = "[CTRL]+[A]"
    },
    -- {
    --     szName = "物件缩放",
    --     szHotkey = "[O]"
    -- },
    {
        szName = "隐藏/显示界面",
        szHotkey = "[CTRL]+[U]"
    },
    {
        szName = "物品染色",
        szHotkey = "[1]-[6]"
    },
    {
        szName = "替换",
        szHotkey = "[R]"
    },
    {
        szName = "仓库位置",
        szHotkey = "[L]"
    },
}

-- 重载
function HomelandBulidHotkey.OnReload()
    Event.UnRegAll(self)
    Event.RegEvent()
end

function HomelandBulidHotkey.Init()
    self.RegEvent()
end

function HomelandBulidHotkey.UnInit()
	self.UnRegEvent()
end

function HomelandBulidHotkey.RegEvent()

    Event.Reg(self, EventType.OnWindowsLostFocus, function()
        self.bIsCtrlDown = false
    end)

	Event.Reg(self, EventType.OnKeyboardUp, function(nKeyCode, szKey)
        if nKeyCode == cc.KeyCode.KEY_CTRL then
            self.bIsCtrlDown = false
        elseif nKeyCode == cc.KeyCode.KEY_S then
            if self.bIsCtrlDown then
                Event.Dispatch(EventType.OnHomeLandBuildResponseKey, szKey, self.bIsCtrlDown)
            end
        elseif nKeyCode == cc.KeyCode.KEY_A then
            if self.bIsCtrlDown then
                Event.Dispatch("LUA_HOMELAND_ENTER_MULTI_CHOOSE_MODE")
                HLBOp_Select.SelectAll()
            end
        elseif nKeyCode == cc.KeyCode.OEMMinus then
            HLBOp_Camera.OnOEMMinusKeyUp()
        elseif nKeyCode == cc.KeyCode.OEMPlus then
            HLBOp_Camera.OnOEMPlusKeyUp()
        elseif nKeyCode == cc.KeyCode.OEMComma then
            HLBOp_Camera.OnOEMCommaKeyUp()
        elseif nKeyCode == cc.KeyCode.OEMPeriod then
            HLBOp_Camera.OnOEMPeriodKeyUp()
        elseif nKeyCode == cc.KeyCode.KEY_X then
            if self.bIsCtrlDown then
                return
            end
            local nAngles = Homeland_GetKeyXAngles()
            Event.Dispatch(EventType.OnHomeLandBuildResponseKey, szKey, nAngles)
            HLBOp_Blueprint.RotationBlueprint()
        elseif nKeyCode == cc.KeyCode.KEY_C then
            if self.bIsCtrlDown then
                self.Copy()
            elseif not self.bIsCtrlDown then
                Event.Dispatch(EventType.OnHomeLandBuildResponseKey, szKey, 0)
            end
        elseif nKeyCode == cc.KeyCode.KEY_Y then
            if self.bIsCtrlDown then
                HLBOp_Select.ClearSelect()
                HLBOp_Place.CancelPlace()
                HLBOp_Brush.CancelBrush()
                HLBOp_Bottom.CancelBottom()
                HLBOp_MultiItemOp.CancelPlace()
                HLBOp_CustomBrush.CancelCustomBrush()
                HLBOp_Blueprint.CancelMoveBlueprint()
                if HLBOp_Check.CheckNoHint() then
                    HLBOp_Step.Redo()
                end
            end
        elseif nKeyCode == cc.KeyCode.KEY_Z then
            if self.bIsCtrlDown then
                HLBOp_Select.ClearSelect()
                HLBOp_Place.CancelPlace()
                HLBOp_Brush.CancelBrush()
                HLBOp_Bottom.CancelBottom()
                HLBOp_MultiItemOp.CancelPlace()
                HLBOp_CustomBrush.CancelCustomBrush()
                HLBOp_Blueprint.CancelMoveBlueprint()
                if HLBOp_Check.CheckNoHint() then
                    HLBOp_Step.Undo()
                end
            elseif not self.bIsCtrlDown then
                Event.Dispatch(EventType.OnHomeLandBuildResponseKey, szKey, 0)
            end
        elseif nKeyCode == cc.KeyCode.KEY_V then
            if self.bIsCtrlDown then
                return
            end
            local tSelectObjs = HLBOp_Select.GetSelectInfo()
            if tSelectObjs.bSingle then
                HLBOp_Place.StartMoveItem(tSelectObjs[1])
            elseif not tSelectObjs.bSingle then
                HLBOp_MultiItemOp.StartMove()
            end
            HLBOp_Main.SetMoveObjEnabled(true)
            Event.Dispatch(EventType.OnHomeLandBuildResponseKey, szKey)
        elseif nKeyCode == cc.KeyCode.KEY_U then
            if self.bIsCtrlDown then
                Event.Dispatch(EventType.OnHomeLandBuildResponseKey, szKey, self.bIsCtrlDown)
            end
        elseif nKeyCode == cc.KeyCode.KEY_ESCAPE then
            HLBOp_Select.ClearSelect()
            HLBOp_Place.CancelPlace()

            HLBOp_Brush.CancelBrush()
            HLBOp_Bottom.CancelBottom()
            HLBOp_MultiItemOp.CancelPlace()
            HLBOp_CustomBrush.CancelCustomBrush()
            HLBOp_Blueprint.CancelMoveBlueprint()
            if HomelandInput.IsMultiChooseMode() then
                HomelandInput.ExitMultiChooseMode()
                Event.Dispatch(EventType.OnHomelandExitMultiChoose)
            end
        elseif nKeyCode == cc.KeyCode.KEY_DELETE or nKeyCode == cc.KeyCode.KEY_KP_DELETE then
            local tSelectObjs = HLBOp_Select.GetSelectInfo()
            if #tSelectObjs == 1 then
                HLBOp_SingleItemOp.Destroy(tSelectObjs[1])
            elseif #tSelectObjs > 1 then
                HLBOp_MultiItemOp.Destroy()
            end
        -- elseif nKeyCode == cc.KeyCode.KEY_A then
        -- elseif nKeyCode == cc.KeyCode.KEY_A then
        -- elseif nKeyCode == cc.KeyCode.KEY_A then
        -- elseif nKeyCode == cc.KeyCode.KEY_A then
        -- elseif nKeyCode == cc.KeyCode.KEY_A then
        end
    end)

    Event.Reg(self, EventType.OnKeyboardDown, function(nKeyCode, szKey)
        if nKeyCode == cc.KeyCode.KEY_CTRL then
            self.bIsCtrlDown = true
        elseif nKeyCode == cc.KeyCode.KEY_Z then
            if not self.bIsCtrlDown then
                local nAngles = Homeland_GetKeyZCAngles()
                Event.Dispatch(EventType.OnHomeLandBuildResponseKey, szKey, nAngles)
            end
        elseif nKeyCode == cc.KeyCode.KEY_C then
            if not self.bIsCtrlDown then
                local nAngles = -Homeland_GetKeyZCAngles()
                Event.Dispatch(EventType.OnHomeLandBuildResponseKey, szKey, nAngles)
            end
        elseif nKeyCode == cc.KeyCode.OEMComma then
            HLBOp_Camera.OnOEMCommaKeyDown()
        elseif nKeyCode == cc.KeyCode.OEMPeriod then
            HLBOp_Camera.OnOEMPeriodKeyDown()
        elseif nKeyCode == cc.KeyCode.KEY_F6 then
            HLBOp_Other.SwitchCamView()
        elseif nKeyCode == cc.KeyCode.KEY_F5 then
            if HLBOp_Check.Check() then
                local tSelectObjs = HLBOp_Select.GetSelectInfo()
                if #tSelectObjs == 1 then
                    HLBOp_Other.FocusObject(tSelectObjs[1])
                end
            end
        elseif nKeyCode == cc.KeyCode.KEY_F1 then
            Event.Dispatch(EventType.OnHomeLandBuildResponseKey, szKey, self.bIsCtrlDown)
        elseif nKeyCode == cc.KeyCode.KEY_F2 then
            HLBOp_Camera.SwitchIndoorsMode()
            if HLBOp_Camera.IsCameraIndoorsMode() then
                TipsHelper.ShowNormalTip(g_tStrings.STR_HOMELAND_SWITCHED_TO_CAMERA_INDOORS)
            else
                TipsHelper.ShowNormalTip(g_tStrings.STR_HOMELAND_SWITCHED_TO_CAMERA_OUTDOORS)
            end
        elseif nKeyCode == cc.KeyCode.KEY_F3 then
            g_HomelandBuildingData.bShowGrid = not g_HomelandBuildingData.bShowGrid
            HLBOp_Other.SetGrid(g_HomelandBuildingData.bShowGrid)
        elseif nKeyCode == cc.KeyCode.KEY_F4 then
            g_HomelandBuildingData.bGridAlignEnabled = not g_HomelandBuildingData.bGridAlignEnabled
            if g_HomelandBuildingData.bGridAlignEnabled then
                TipsHelper.ShowNormalTip(g_tStrings.STR_HOMELAND_SWITCHED_TO_GRID_ALIGNMENT)
            else
                TipsHelper.ShowNormalTip(g_tStrings.STR_HOMELAND_SWITCHED_TO_FREE_PLACEMENT)
            end
            HLBOp_Other.SetGridAlignment(g_HomelandBuildingData.bGridAlignEnabled)
        elseif nKeyCode == cc.KeyCode.KEY_R then
            Event.Dispatch(EventType.OnHomeLandBuildResponseKey, szKey, self.bIsCtrlDown)
        elseif nKeyCode == cc.KeyCode.KEY_L then
            Event.Dispatch(EventType.OnHomeLandBuildResponseKey, szKey, self.bIsCtrlDown)
        elseif tonumber(szKey) then
            -- 可以转为数字，直接发
            Event.Dispatch(EventType.OnHomeLandBuildResponseKey, szKey, self.bIsCtrlDown)
        elseif nKeyCode == cc.KeyCode.KEY_LEFT_BRACKET then
            Event.Dispatch(EventType.OnHomeLandBuildResponseKey, szKey, self.bIsCtrlDown)
        elseif nKeyCode == cc.KeyCode.KEY_RIGHT_BRACKET then
            Event.Dispatch(EventType.OnHomeLandBuildResponseKey, szKey, self.bIsCtrlDown)
        -- elseif nKeyCode == cc.KeyCode.KEY_A then
        -- elseif nKeyCode == cc.KeyCode.KEY_A then
        end
    end)
end

function HomelandBulidHotkey.UnRegEvent()
    Event.UnReg(self, EventType.OnKeyboardUp)
    Event.UnReg(self, EventType.OnKeyboardDown)
end

local function GetHotkeyDescWithImg(tbKeyInfo)
    local nHotkeyNum = 0
    local nHotkeyWidth = 0
    local szHotkey = tbKeyInfo.szHotkey
    local tbKeycode = string.gmatch(szHotkey, "%[([^%]]+)%]")
    for key in tbKeycode do
        local szFrame = tbKeycode2Img[key]
        local szFrameWidth = string.match(szFrame, "width=\'(.-)\'")
        szHotkey = string.gsub(szHotkey, "%[([^%]]+)%]", szFrame, 1)
        nHotkeyNum = nHotkeyNum + 1
        nHotkeyWidth = nHotkeyWidth + tonumber(szFrameWidth)
    end
    szHotkey = string.gsub(szHotkey, "[%[%]]", "")
    return szHotkey, nHotkeyNum, nHotkeyWidth
end

function HomelandBulidHotkey.GetHomeBuildHotkeyList()
    local bFlag = false
    local tbHotkeyList = {}
    for nIndex, tbKey in pairs(tbBulidHotkeyList) do
        local szContent, nHotkeyNum, nHotkeyWidth = GetHotkeyDescWithImg(tbKey)
        if nHotkeyNum >= 2 then
            table.insert(tbHotkeyList, {{szTitle = tbKey.szName, szContent = szContent}})
        elseif nHotkeyNum < 2 and bFlag then
            table.insert(tbHotkeyList[#tbHotkeyList], {szTitle = tbKey.szName, szContent = szContent})
            bFlag = false
        else
            table.insert(tbHotkeyList, {{szTitle = tbKey.szName, szContent = szContent}})
            bFlag = true
        end
    end
    return tbHotkeyList
end

function HomelandBulidHotkey.Copy()
    local tObjIDs = HLBOp_Select.GetSelectInfo()
    if not HLBOp_Check.CheckCopy() then
        return
    end
    if #tObjIDs == 1 then
        local dwModelID = HLBOp_Amount.GetModelIDByObjID(tObjIDs[1])
        if FurnitureData.IsAutoBottomBrush(dwModelID) then
            TipsHelper.ShowNormalTip(g_tStrings.STR_HOMELAND_BUILDING_CANT_COPY_ITEM)
            return
        end
        HLBOp_SingleItemOp.Copy()
    elseif #tObjIDs > 1 then
        for i = 1, #tObjIDs do
            local dwModelID = HLBOp_Amount.GetModelIDByObjID(tObjIDs[i])
            if FurnitureData.IsAutoBottomBrush(dwModelID) then
                TipsHelper.ShowNormalTip(g_tStrings.STR_HOMELAND_BUILDING_CANT_COPY_ITEM)
                return
            end
        end
        HLBOp_MultiItemOp.Copy()
    end
end

function HomelandBulidHotkey.GetCtrlDown()
    return self.bIsCtrlDown
end
