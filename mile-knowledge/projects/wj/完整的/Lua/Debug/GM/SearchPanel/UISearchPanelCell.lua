-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UISearchPanelCell
-- Date: 2022-12-30 11:21:27
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UISearchPanelCell = class("UISearchPanelCell")

function UISearchPanelCell:OnEnter(tbPanel, tbCell)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbPanel = tbPanel
    self.tbCell = tbCell
    self:UpdateInfo()
end

function UISearchPanelCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UISearchPanelCell:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnSelect, EventType.OnClick, function(btn)
        if self.tbCell.szText then
            if self.tbCell.callback then
                self.tbCell.callback()
            else
                SendGMCommand(self.tbCell.szGMCMD)
            end
        else
            self.tbPanel.SearchPanelRight:setVisible(true)
            local szMapName = UIHelper.GetString(self.tbPanel.LabelDropList)
            SearchPanel.OnClickCell(szMapName, self)
        end
    end)
end

function UISearchPanelCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UISearchPanelCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UISearchPanelCell:UpdateInfo()
    if self.tbCell.szGMCMD then
        UIHelper.SetString(self.LabelInfo, self.tbCell.szText)
    else
        if SearchPanel.szInfoType == "NPCList" then
            local szText = UIHelper.GBKToUTF8(self.tbCell.szName) .. ",数量:" .. self.tbCell.nCount .. self.tbCell.Source
            UIHelper.SetString(self.LabelInfo, szText)
        elseif SearchPanel.szInfoType == "NPC" then
            local szText = UIHelper.GBKToUTF8(self.tbCell.szName) .. ",Index:" .. self.tbCell.nIndex
            UIHelper.SetString(self.LabelInfo, szText)
        end

        if #SearchPanel.tInfo == 1 then
            SearchPanel.tLastCell = nil
            self.tbPanel.SearchPanelRight:setVisible(true)
            local szMapName = UIHelper.GetString(self.tbPanel.LabelDropList)
            SearchPanel.OnClickCell(szMapName, self)
        end
    end
end


return UISearchPanelCell