-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPanelCreatorNameView
-- Date: 2023-07-24 09:34:52
-- Desc: ?
-- ---------------------------------------------------------------------------------


local nBaseSpeed = 3
local nMaxRatio = 2
local nMinRatio = 0.5

local UIPanelCreatorNameView = class("UIPanelCreatorNameView")

function UIPanelCreatorNameView:OnEnter()
    require("ui/String/Credits.lua")

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    UIMgr.HideView(VIEW_ID.PanelLogin)
    self:Init()
end

function UIPanelCreatorNameView:OnExit()
    self.bInit = false
    self:UnRegEvent()
    UIMgr.ShowView(VIEW_ID.PanelLogin)

    package.loaded["ui/String/Credits.lua"] = nil
    _G["tCredits"] = nil
end

function UIPanelCreatorNameView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnChangeVision, EventType.OnClick, function()
        local nViewID = VIEW_ID.PanelVisionPop
        local fn = UIMgr.GetView(nViewID) and UIMgr.Close or UIMgr.Open
        fn(nViewID)
    end)

    UIHelper.BindUIEvent(self.BtnSpeedUp, EventType.OnClick, function()
        self.nRatio = math.min(self.nRatio + 0.25, nMaxRatio)
        self.nSpeed = nBaseSpeed * self.nRatio
        self:UpdateLabelSpeed()
    end)

    UIHelper.BindUIEvent(self.BtnSpeedCut, EventType.OnClick, function()
        self.nRatio = math.max(self.nRatio - 0.25, nMinRatio)
        self.nSpeed = nBaseSpeed * self.nRatio
        self:UpdateLabelSpeed()
    end)

    UIHelper.BindUIEvent(self.BtnPause, EventType.OnClick, function()
        UIHelper.SetVisible(self.BtnPause, false)
        UIHelper.SetVisible(self.BtnPlay, true)
        self:StopTimer()
    end)

    UIHelper.BindUIEvent(self.BtnPlay, EventType.OnClick, function()
        UIHelper.SetVisible(self.BtnPause, true)
        UIHelper.SetVisible(self.BtnPlay, false)
        self:StartTimer()
    end)

    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)
end

function UIPanelCreatorNameView:RegEvent()
    Event.Reg(self, EventType.OnSelectVersion, function(nIndex)
        self:SetVersion(nIndex)
    end)

end

function UIPanelCreatorNameView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIPanelCreatorNameView:Init()
    self.nSpeed = nBaseSpeed
    self.nRatio = 1

    for nIndex = 1, 20 do
        UIHelper.AddPrefab(PREFAB_ID.WidgetEmpty, self.ScrollViewNameList)
    end
    self:SetVersion(#tStrCreditsVersion)
    self:StartTimer()
end

function UIPanelCreatorNameView:StartTimer()
    self:StopTimer()
    self.nTimer = Timer.AddFrameCycle(self, 1, function()
        self:UpdatePosition()
    end)
end

function UIPanelCreatorNameView:StopTimer()
    if self.nTimer then
        Timer.DelTimer(self, self.nTimer)
        self.nTimer = nil
    end
end


-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelCreatorNameView:RemoveChild()
    if self.tbScriptView then
        for index, scriptView in ipairs(self.tbScriptView) do
            UIHelper.RemoveFromParent(scriptView._rootNode)
        end
    end
    self.tbScriptView = {}
end

function UIPanelCreatorNameView:UpdateInfo()

    self:RemoveChild()
    self.scriptName = nil

    for nIndex, tbData in ipairs(self.tbNameList) do
        if tbData[1] == "title" then
            self.scriptName = nil
            local scriptName = UIHelper.AddPrefab(PREFAB_ID.WidgetTittle, self.ScrollViewNameList, tbData)
            table.insert(self.tbScriptView, scriptName)
        elseif tbData[1] == "name" then
            self:AddName(tbData)
        elseif tbData[1] == "logo" then
            self.scriptName = nil
            local szUITexPath = tbData[4]
            local nUITexFrame = tbData[5]
            if tMobileIconPath[szUITexPath] and tMobileIconPath[szUITexPath][nUITexFrame] then
                local szImage = tMobileIconPath[szUITexPath][nUITexFrame]
                local scriptName = UIHelper.AddPrefab(PREFAB_ID.WidgetImgLogo, self.ScrollViewNameList, szImage)
                table.insert(self.tbScriptView, scriptName)
            end
        end
    end
    UIHelper.ScrollViewDoLayout(self.ScrollViewNameList)
    UIHelper.ScrollToPercent(self.ScrollViewNameList, 0)

    local tbVersionInfo = tStrCreditsVersion[self.nVersion]
    local szUITexPath = tbVersionInfo[2]
    local nUITexFrame = tbVersionInfo[3]
    if tMobileIconPath[szUITexPath] and tMobileIconPath[szUITexPath][nUITexFrame] then
        local szImage = tMobileIconPath[szUITexPath][nUITexFrame]
        UIHelper.SetTexture(self.ImgVersionLogo, UIHelper.UTF8ToGBK(szImage))
    end

    UIHelper.SetVisible(self.ImgVersionLogo, not table.contain_value(tHideTitleVersion, self.nVersion))

    for nIndex, szImage in pairs(tMainTitleImage) do
        if self.nVersion <= nIndex then
            UIHelper.SetTexture(self.ImgLogo, UIHelper.UTF8ToGBK(szImage))
            break
        end
    end

    UIHelper.SetTouchEnabled(self.ScrollViewNameList, false)--不禁掉拖拽滑动的两个问题：①如果内容在Scrollview外，拖拽后会导致立即修正到scrollView内 ②、拖拽滑动C++每帧会自己计算位置，在此过程中lua计算的位置会被修正，会出现滑动停止一段时间的效果
    local nWidth = UIHelper.GetWidth(self.ScrollViewNameList)
    local nX, nY = UIHelper.GetScrolledPosition(self.ScrollViewNameList)
    local nStartPosX = nX + nWidth
    UIHelper.SetScrolledPosition(self.ScrollViewNameList, nStartPosX, nY)
end

function UIPanelCreatorNameView:UpdateLabelSpeed()
    UIHelper.SetVisible(self.LabelSpeed, self.nRatio ~= 1)
    UIHelper.SetString(self.LabelSpeed, string.format("%s倍速播放中", self.nRatio))
end

function UIPanelCreatorNameView:AddName(tbData)
    if self.scriptName and UIHelper.GetUtf8Len(tbData[4]) <=5 then
        local bAddSuccess = self.scriptName:AddChild(tbData)
        if bAddSuccess then return end
    end
    local scriptName = UIHelper.AddPrefab(PREFAB_ID.WidgetName, self.ScrollViewNameList)
    table.insert(self.tbScriptView, scriptName)
    self.scriptName = scriptName
    self.scriptName:AddChild(tbData)
end


function UIPanelCreatorNameView:UpdatePosition()
    local nX, nY = UIHelper.GetScrolledPosition(self.ScrollViewNameList)
    UIHelper.SetScrolledPosition(self.ScrollViewNameList, nX - self.nSpeed, nY)

    local nInnerWidth, nInnerHeight = UIHelper.GetInnerContainerSize(self.ScrollViewNameList)
    if nX <= -nInnerWidth then
        UIMgr.Close(self)
    end
end


function UIPanelCreatorNameView:SetVersion(nVersion)
    self.nVersion = nVersion
    self:UpdateNameList()
end

function UIPanelCreatorNameView:UpdateNameList()
    self.tbNameList = tCredits[self.nVersion]
    self:UpdateInfo()
end

return UIPanelCreatorNameView