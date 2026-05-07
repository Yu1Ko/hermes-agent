-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPanelWanlingMonster
-- Date: 2025-08-13 16:53:13
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIPanelWanlingMonster = class("UIPanelWanlingMonster")
local MONSTER_CLASS_NUM = 6
local tbMonsterImgList = {
    [5] = "UIAtlas2_SkillDX_SpecialSkill_WanLing_zj",
    [6] = "UIAtlas2_SkillDX_SpecialSkill_WanLing_zs",
    [8] = "UIAtlas2_SkillDX_SpecialSkill_WanLing_fx",
    [9] = "UIAtlas2_SkillDX_SpecialSkill_WanLing_rd",
    [7] = "UIAtlas2_SkillDX_SpecialSkill_WanLing_qg",
    [13] = "UIAtlas2_SkillDX_SpecialSkill_WanLing_kz",
}

local tbnFrame2MonsterClass = {
    [5] = "Imglang",
    [6] = "Imglaohu",
    [8] = "Imgniao",
    [9] = "Imgxiong",
    [7] = "Imgdaxiang",
    [13] = "Imgyezhu",
}

function UIPanelWanlingMonster:OnEnter(nType)
    self.dwOpenType = nType
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo()
end

function UIPanelWanlingMonster:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPanelWanlingMonster:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)


    UIHelper.BindUIEvent(self.BtnGo, EventType.OnClick, function()
        local player = GetClientPlayer()
        if not player then
            return
        end

        if not self:CheckPlayerState() then
            return
        end

        local tSelectInfo = clone(self.tSelectedMonster)
        local tNowSet = self.tSelectedMonster[self.dwSelectTrough]
        tSelectInfo[self.dwSelectTrough] = {dwBeastPetType = tNowSet.dwBeastPetType, dwBeastPetID = self.dwSelectMonster}
        local bSuccess = player.SetSelectBeastPet(tSelectInfo)
        if bSuccess then
            OutputMessage("MSG_SYS", g_tStrings.STR_BEAST_SET_SUCCESS)
        else
            OutputMessage("MSG_SYS", g_tStrings.STR_BEAST_SET_FAILURE)
        end
    end)
end

function UIPanelWanlingMonster:RegEvent()
    Event.Reg(self, "UPDATE_BEAST_PET_DATA", function ()
        self:UpdateExistMonster()
        self:UpdateSkillPetSet()

        self:UpdateMonsterTrough()
        self:UpdateSelectTroughPage()
    end)

    Event.Reg(self, "ACQUIRE_BEAST_PET", function ()
        self:UpdateExistMonster()
        self:UpdateSkillPetSet()

        self:UpdateMonsterTrough()
        self:UpdateSelectTroughPage()
    end)

    Event.Reg(self, "UPDATE_SELECT_BEAST_PET", function ()
        self:UpdateExistMonster()
        self:UpdateSkillPetSet()

        self:UpdateMonsterTrough()
        self:UpdateSelectTroughPage()
    end)

    Event.Reg(self, EventType.OnViewOpen, function (nViewID)
        if nViewID ~= VIEW_ID.PanelWanLingAnimalEditPop then
            UIMgr.Close(self)
        end
    end)
end

function UIPanelWanlingMonster:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelWanlingMonster:UpdateInfo()
    self:Init()
    self:UpdateMonsterTrough()
    self:UpdateSelectTroughPage()
end

function UIPanelWanlingMonster:Init()
    self.dwSelectTrough = 1
    self.dwSelectMonster = 0
    self.tExistMonster = {}
    self.tMonsterClassUI = Table_GetWLBeastClass()
    self:UpdateExistMonster()
    self:UpdateSkillPetSet()
end

function UIPanelWanlingMonster:UpdateExistMonster()
    local player = GetClientPlayer()
    if not player then
        return
    end

    local tExistMonster = {}
    local tExistSkillPet = player.GetExistBeastPetIndexes()
    for _, dwID in ipairs(tExistSkillPet) do
        tExistMonster[dwID] = true
    end
    self.tExistMonster = tExistMonster

    local function fnCmp(a, b)
        if a.bExist and b.bExist then
            return a.dwID < b.dwID
        elseif a.bExist then
            return true
        elseif b.bExist then
            return false
        else
            return a.dwID < b.dwID
        end
    end

    local tMonsterInfoUI = {}
    for i = 1, MONSTER_CLASS_NUM do
        local tList = Table_GetWLBeastInfoByClassID(i)
        for _, tMonster in ipairs(tList) do
            if tExistMonster[tMonster.dwID] then
                tMonster.bExist = true
            else
                tMonster.bExist = false
            end
        end
        table.sort(tList, fnCmp)
        tMonsterInfoUI[i] = tList
    end
    self.tMonsterInfoUI = tMonsterInfoUI
end

function UIPanelWanlingMonster:UpdateSkillPetSet()
    local player = GetClientPlayer()
    if not player then
        return
    end

    self.tSelectedMonster = player.GetSelectBeastPet()
    if self.dwOpenType then
        for i, tSelect in ipairs(self.tSelectedMonster) do
            if tSelect.dwBeastPetType == self.dwOpenType then
                self.dwSelectTrough = i
            end
        end
        self.dwOpenType = nil
    end
end

function UIPanelWanlingMonster:UpdateMonsterTrough()
    local nIndex = 1
    self.tbCellScriptList = self.tbCellScriptList or {}
    UIHelper.ToggleGroupRemoveAllToggle(self.ToggleGroup)
    for i = 1, MONSTER_CLASS_NUM, 1 do
        local tSelectInfo = self.tSelectedMonster[i]
        local tUIInfo = self.tMonsterClassUI[tSelectInfo.dwBeastPetType]
        if tUIInfo then
            local szFrame = tbMonsterImgList[tUIInfo.nFrame]
            local tbScript = self.tbCellScriptList[i] or UIHelper.AddPrefab(PREFAB_ID.WidgetWanLingAnimalCell, self.LayoutEditAnimal)
            if tbScript then
                UIHelper.ToggleGroupAddToggle(self.ToggleGroup, tbScript.TogAnimalCell)
                UIHelper.SetSelected(tbScript.TogAnimalCell, false)
                UIHelper.SetSpriteFrame(tbScript.ImgIcon, szFrame)
                UIHelper.SetString(tbScript.LabelTitle, tostring(i))
                UIHelper.BindUIEvent(tbScript.TogAnimalCell, EventType.OnSelectChanged, function(toggle, bSelected)
                    if self.dwSelectTrough ~= i and bSelected then
                        self.dwSelectTrough = i
                        self:UpdateSelectTroughPage()
                    end
                end)
                tbScript:SetAnimalInfo(i, tUIInfo)
                self.tbCellScriptList[i] = tbScript
            end
            if self.dwSelectTrough == i then
                nIndex = i
            end
        end
    end
    UIHelper.SetToggleGroupSelected(self.ToggleGroup, nIndex - 1)  
    self:UpdateSwap()
end

function UIPanelWanlingMonster:UpdateSelectTroughPage()
    local tSelectInfo = self.tSelectedMonster[self.dwSelectTrough]
    local tUIInfo = self.tMonsterClassUI[tSelectInfo.dwBeastPetType]
    if tUIInfo then
        local szFrame = tbMonsterImgList[tUIInfo.nFrame]
        UIHelper.RemoveAllChildren(self.WidgetSkill)
        local tbScript = UIHelper.AddPrefab(PREFAB_ID.WidgetWanLingAnimalCell, self.WidgetSkill)
        if tbScript then
            UIHelper.SetSpriteFrame(tbScript.ImgIcon, szFrame)
            UIHelper.SetString(self.LabelAnimalType, UIHelper.GBKToUTF8(tUIInfo.szName))
            UIHelper.SetVisible(tbScript.LabelTitle, false)
            UIHelper.SetVisible(tbScript.ImgNumBg_Select, false)
            UIHelper.SetVisible(tbScript.ImgSelect, false)
            UIHelper.SetEnable(tbScript.TogAnimalCell, false)
        end
    end
    if self.dwSelectMonster == 0 then
        self.dwSelectMonster = tSelectInfo.dwBeastPetID or 0
    else
        if self.dwSelectMonster ~= tSelectInfo.dwBeastPetID then
            self.dwSelectMonster = tSelectInfo.dwBeastPetID
        end
    end

    self:UpdatePageInfo()
    self:PreviewMonster(tUIInfo.nFrame)
end

function UIPanelWanlingMonster:UpdatePageInfo()
    local tSelectInfo = self.tSelectedMonster[self.dwSelectTrough]
    local tMonsterList = self.tMonsterInfoUI[tSelectInfo.dwBeastPetType] or {}

    local tMonster = tMonsterList[1]
    if tMonster then
        UIHelper.RemoveAllChildren(self.LayoutAnimalTog)
        local tbScript = UIHelper.AddPrefab(PREFAB_ID.WidgetAnimalTog, self.LayoutAnimalTog)
        UIHelper.SetString(tbScript.LabelAnimalType, UIHelper.GBKToUTF8(tMonster.szName))
        local szContent = ParseTextHelper.ParseNormalText(UIHelper.GBKToUTF8(tMonster.szDesc))
        UIHelper.SetString(self.LabelDescribe, szContent)
    end

    if self.dwSelectMonster ~= tSelectInfo.dwBeastPetID and self.tExistMonster[self.dwSelectMonster] then
        UIHelper.SetVisible(self.BtnGo, true)
    else
        UIHelper.SetVisible(self.BtnGo, false)
    end
end

function UIPanelWanlingMonster:PreviewMonster(nFrame)
    if not nFrame then
        return
    end
    local szAnimalClass = tbnFrame2MonsterClass[nFrame]
    for i, node in ipairs(self.tbAnimalImgList) do
        if UIHelper.GetName(node) == szAnimalClass then
            UIHelper.SetVisible(node, true)
        else
            UIHelper.SetVisible(node, false)
        end
    end
end

function UIPanelWanlingMonster:CheckPlayerState()
    if IsInFight() then
        OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_CAN_NOT_OPERATE_IN_FIGHT)
        OutputMessage("MSG_SYS", g_tStrings.STR_CAN_NOT_OPERATE_IN_FIGHT)
        return false
    end
    return true
end

function UIPanelWanlingMonster:UpdateSwap()
    if not self.tbCellScriptList or table.is_empty(self.tbCellScriptList) then
        return
    end
    for i, script in ipairs(self.tbCellScriptList) do
        local fnDragStart = function(nX, nY)
            return self:DragStart(script)
        end
        local fnDragMoved = function(nX, nY)
            self:MoveNode(nX, nY)
        end
        local fnDragEnd = function(nX, nY)
            self:DragEnd(nX, nY)
        end
        script:BindMoveFunction(fnDragStart, fnDragMoved, fnDragEnd)
    end
end

function UIPanelWanlingMonster:DragStart(tAnimalScript)
    if not self.tSelectedInfo then
        local nIndex, tAnimalData = tAnimalScript:GetAnimalInfo()
        local szFrame = tbMonsterImgList[tAnimalData.nFrame]
        self.tSelectedInfo = {
            tbData = {
                szFrame = szFrame,
                dwOrgIndex = nIndex
            },
            
            tSkillScript = tAnimalScript,
        }
        self:SetBlackMaskVisible(true)
        self.nTouchBeganX, self.nTouchBeganY = UIHelper.GetPosition(tAnimalScript._rootNode)
        self.tCursor = GetViewCursorPoint()
        return true
    end
    return false
end

function UIPanelWanlingMonster:MoveNode(nX, nY)
    if self.draggableNode then
        local node = self.draggableNode._rootNode
        self.tCursor = GetViewCursorPoint()

        local nodeX, nodeY = UIHelper.ConvertToNodeSpace(UIHelper.GetParent(node), nX, nY)
        local w, h = UIHelper.GetContentSize(node)
        UIHelper.SetPosition(node, nodeX - w / 2, nodeY - h / 2)
    end
end

function UIPanelWanlingMonster:DragEnd(nX, nY)
    local nSlotIndex = self:CollectNodeByPoint(nX, nY)  --要替换的节点index
    if nSlotIndex >= 1 then
        local dwOrgIndex = self.tSelectedInfo.tbData.dwOrgIndex
        if dwOrgIndex ~= nSlotIndex then
            local tOrgInfo = self.tSelectedMonster[dwOrgIndex]
            local tInInfo = self.tSelectedMonster[nSlotIndex]
            local tSelectInfo = clone(self.tSelectedMonster)
            if tOrgInfo and tInInfo then
                tSelectInfo[dwOrgIndex] = tInInfo
                tSelectInfo[nSlotIndex] = tOrgInfo
                local player = GetClientPlayer()
                if player then
                    local bSuccess = player.SetSelectBeastPet(tSelectInfo)
                    if bSuccess then
                        OutputMessage("MSG_SYS", g_tStrings.STR_BEAST_ORDER_SUCCESS)
                    else
                        OutputMessage("MSG_SYS", g_tStrings.STR_BEAST_ORDER_FAILURE)
                    end
                end
            end
        end
    end
    self:SetBlackMaskVisible(false)
    self.tSelectedInfo = nil
    self.tCursor = nil
end

function UIPanelWanlingMonster:SetBlackMaskVisible(bShowMask)
    local tSkillScript = self.tSelectedInfo.tSkillScript
    local tDraggableParent = self.DraggableParent

    if bShowMask then
        local worldX, worldY = UIHelper.GetWorldPosition(tSkillScript._rootNode)
        local nodeX, nodeY = UIHelper.ConvertToNodeSpace(tDraggableParent, worldX, worldY)

        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetSkillCell1, tDraggableParent)
        local szFrame = self.tSelectedInfo.tbData.szFrame
        script:UpdateInfoWanLing(szFrame)
        script:HideLabel()
        script:SetSelected(true)
        script:SetSelectEnable(false)
        UIHelper.SetPosition(script._rootNode, nodeX, nodeY)

        self.draggableNode = script
    end

    if not bShowMask then
        UIHelper.RemoveAllChildren(tDraggableParent)
        self.draggableNode = nil
    end
end

local function _forEachValidNode(node, func)
    -- 筛选widget
    if not node then
        return
    end
    if node:getName() == "PanelHoverTips" then
        return
    end
    if node:getName() == "PanelNodeExplorer" then
        return
    end
    if not UIHelper.GetVisible(node) then
        return
    end
    if node.isEnabled and not node:isEnabled() then
        return
    end

    local aChildren = node:getChildren()
    if aChildren then
        for i = 1, #aChildren do
            local childNode = aChildren[i]
            if UIHelper.GetVisible(childNode) and (not childNode.isEnabled or childNode:isEnabled()) then
                func(childNode)
                _forEachValidNode(childNode, func)
            end
        end
    end
end

function UIPanelWanlingMonster:CollectNodeByPoint()
    local x, y = self.tCursor.x, self.tCursor.y
    local tbPoint = cc.p(x, y) -- 鼠标位置的世界坐标

    --DebugDraw.DrawCircle(tbPoint, 10)

    local sceneNode = cc.Director:getInstance():getRunningScene()
    local camera = sceneNode:getDefaultCamera()
    local tbNodes = {}

    -- 遍历所有节点
    _forEachValidNode(sceneNode, function(node)
        local bIsHit = false

        -- hitTest for button etc.
        if node.hitTest and node:hitTest(tbPoint, camera) then
            if node:isClippingParentContainsPoint(tbPoint) then
                bIsHit = true
                table.insert(tbNodes, node)
            end
        end
    end)

    --local tAvailableSlotList = self:GetRightSlotList(self.tSelectedInfo.tSlotData, self.tSelectedInfo.nStartSlot)

    for nSlotIndex, script in pairs(self.tbCellScriptList) do
        if table.contain_value(tbNodes, script:GetToggle()) then
            return nSlotIndex
        end
    end

    return -1
end

return UIPanelWanlingMonster