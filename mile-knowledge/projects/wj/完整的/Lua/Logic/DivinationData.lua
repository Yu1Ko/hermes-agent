-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: DivinationData
-- Date: 2023-05-17 16:40:19
-- Desc: ?
-- ---------------------------------------------------------------------------------

DivinationData = DivinationData or {}
local self = DivinationData
-------------------------------- 消息定义 --------------------------------
DivinationData.Event = {}
DivinationData.Event.XXX = "DivinationData.Msg.XXX"

local tDivination = {
    Path = "\\UI\\Scheme\\Case\\Divination.txt",
    Title = {
        {f = "i", t = "nIndex"},
        {f = "p", t = "szStickSFX"},
        {f = "p", t = "szStickWaitingSFX"},
        {f = "p", t = "szDivinationAfterBG"},
        {f = "i", t = "nDivinationAfterFrame"},
        {f = "p", t = "szSignetBGPath"},
        {f = "i", t = "nSignetBGFrame"},
        {f = "p", t = "szSignetPath"},
        {f = "i", t = "nSignetFrame"},
        {f = "s", t = "szSignetTitle"},
        {f = "s", t = "szSignetText"},
        {f = "s", t = "szSignetTip"},
    }
}

function DivinationData.Init()
    if not IsUITableRegister("Divination") then
        RegisterUITable("Divination", tDivination.Path, tDivination.Title)
    end
end

function DivinationData.UnInit()
    
end

function DivinationData.OnLogin()
    
end

function DivinationData.OnFirstLoadEnd()
    
end

function DivinationData.GetDivinationInfo(nIndex)
    local tLine = g_tTable.Divination:Search(nIndex)
    if not tLine then
        return 
    end
    return tLine
end


function DivinationData.UpdateData(tParam)
    if not self.tParam or self.tParam.nIndex ~= tParam.nIndex  then
        self.tInfo = self.GetDivinationInfo(tParam.nIndex)
    end
    self.tParam = tParam
end

function DivinationData.GetParam()
    return self.tParam
end

function DivinationData.GetInfo()
    return self.tInfo
end

function DivinationData.Begin(nIndex)
    local tParam = {nIndex = nIndex, bBegin = true}
    DivinationData.UpdateData(tParam)

    if not UIMgr.IsViewOpened(VIEW_ID.PanelDivination) then
        UIMgr.Open(VIEW_ID.PanelDivination, self.tParam, self.tInfo)
    else
        local scriptView = UIMgr.GetViewScript(VIEW_ID.PanelDivination)
        scriptView:OnEnter(self.tParam, self.tInfo)
    end

end

function DivinationData.End(nIndex, bShowEndSFX)
    local tParam = {nIndex = nIndex, bEnd = true, bShowEndSFX = bShowEndSFX}
    DivinationData.UpdateData(tParam)

    if not UIMgr.IsViewOpened(VIEW_ID.PanelDivination) then
        UIMgr.Open(VIEW_ID.PanelDivination, self.tParam, self.tInfo)
    else
        local scriptView = UIMgr.GetViewScript(VIEW_ID.PanelDivination)
        scriptView:OnEnter(self.tParam, self.tInfo)
    end
end