-- ---------------------------------------------------------------------------------
-- Name: UIWidgeCampCell
-- Desc: 帮会cell
-- Prefab:WidgeCampFactionCell
-- ---------------------------------------------------------------------------------

local UIWidgeCampCell = class("UIWidgeCampCell")

function UIWidgeCampCell:OnEnter(nTongID)
    if not self.bInit then
        self:BindUIEvent()
        self:RegEvent()
        self.bInit = true
    end
    self.nTongID = nTongID
    self:UpdateInfo()
end

function UIWidgeCampCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgeCampCell:BindUIEvent()
    
end

function UIWidgeCampCell:RegEvent()
    
end

function UIWidgeCampCell:UnRegEvent()

end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgeCampCell:UpdateInfo()
    local tbInfo = CommandBaseData.GetTongDataByID(self.nTongID)
    UIHelper.SetString(self.LableFactionName, UIHelper.GBKToUTF8(tbInfo.szTongName))
    UIHelper.SetString(self.LablePlayerName, UIHelper.GBKToUTF8(tbInfo.szMasterName))
    UIHelper.SetString(self.LabelScore, UIHelper.GBKToUTF8(tbInfo.nKey) .. g_tStrings.STR_COMMAND_FEN)

    local tbCastleInfo = CommandBaseData.GetTongCastleInfoByName(szName)
    local szCastleName = CommandBaseData.GetCastleNameByID(nTongID)
    UIHelper.SetString(self.LableCity, UIHelper.GBKToUTF8(szCastleName))
end

return UIWidgeCampCell