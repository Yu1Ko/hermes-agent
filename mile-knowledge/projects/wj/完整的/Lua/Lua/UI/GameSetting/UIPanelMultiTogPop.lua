-- ---------------------------------------------------------------------------------
-- Author: jiayuran
-- Name: UIPanelMultiTogPop
-- Date: 2024-07-15 11:17:33
-- Desc: UIPanelSceneFontSetting
-- ---------------------------------------------------------------------------------
local UIPanelMultiTogPop = class("UIPanelMultiTogPop")

function UIPanelMultiTogPop:OnEnter(tbTogInfos)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIPanelMultiTogPop:Init(szTitle, tbTogInfos)
    self.tScripts = {}
    self.tbTogInfos = tbTogInfos
    UIHelper.SetString(self.LabelTitle, szTitle)
    self:UpdateInfo()
end

function UIPanelMultiTogPop:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPanelMultiTogPop:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)
end

function UIPanelMultiTogPop:RegEvent()
    Event.Reg(self, EventType.OnMultiTogPopRefresh, function()
        self:UpdateInfo()
    end)
end

function UIPanelMultiTogPop:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

---{
--            szLabel = "全部选中",
--            bOccupyWholeLine = true, -- 占据整行 
--            fnOnSelected = function() end
--            fnGetSelected = function() end
--        },
---
function UIPanelMultiTogPop:UpdateInfo()
    local tbTogInfos = self.tbTogInfos
    for nIndex, tTogData in ipairs(tbTogInfos) do
        local script = self.tScripts[nIndex]
        if not script then
            self.tScripts[nIndex] = UIHelper.AddPrefab(PREFAB_ID.WidgetChatSettingGroupOption, self.ScrollViewTogList)
            script = self.tScripts[nIndex]
            if tTogData.bOccupyWholeLine then
                local nWidth = UIHelper.GetWidth(script._rootNode)
                UIHelper.SetWidth(script._rootNode, nWidth * 3)
            end
        end
        script:Init(tTogData.szLabel, tTogData.fnGetSelected(), tTogData.fnOnSelected)
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewTogList)
end

return UIPanelMultiTogPop