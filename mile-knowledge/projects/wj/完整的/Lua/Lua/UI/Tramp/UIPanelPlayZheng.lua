-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPanelPlayZheng
-- Date: 2023-04-24 11:29:02
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIPanelPlayZheng = class("UIPanelPlayZheng")

local tKeyList = {
    "1","2","3","4","5","6","7",
    "8","9","0","OEMMinus","OEMPlus","Q","W",
    "E","R","T","Y","U","I","O",
}

function UIPanelPlayZheng:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    ShortcutInteractionData.SetEnableKeyBoard(false)
    UIMgr.HideLayer(UILayer.Main)
    self:UpdateInfo()
    InputHelper.LockMove(true)
end

function UIPanelPlayZheng:OnExit()
    self.bInit = false
    self:UnRegEvent()
    ShortcutInteractionData.SetEnableKeyBoard(true)
    UIMgr.ShowLayer(UILayer.Main)
    InputHelper.LockMove(false)
end

function UIPanelPlayZheng:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        QTEMgr.ExitDynamicSkillState()
    end)
end

function UIPanelPlayZheng:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIPanelPlayZheng:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelPlayZheng:UpdateInfo()
    local function _insert(tbInfo, nIndex)
        local tData = clone(QTEMgr.GetDynamicSkillData(nIndex))
        tData.key = tKeyList[nIndex]
        table.insert(tbInfo, tData)
    end

    local nCount = QTEMgr.GetDynamicSkillCount()
    local nCol = #self.tbWidgetZheng

    local tbBtnInfo = {}
    for index = 1, nCount / 3 do
        local tbInfo = {}
        _insert(tbInfo, index)
        _insert(tbInfo, index + nCol)
        _insert(tbInfo, index + 2 * nCol)

        table.insert(tbBtnInfo, tbInfo)
    end

    for index, tbInfo in ipairs(tbBtnInfo) do
        local scriptView = UIHelper.GetBindScript(self.tbWidgetZheng[index])
        scriptView:OnEnter(tbInfo)
    end
    UIHelper.LayoutDoLayout(self.LayoutPlayBtn)
end


return UIPanelPlayZheng