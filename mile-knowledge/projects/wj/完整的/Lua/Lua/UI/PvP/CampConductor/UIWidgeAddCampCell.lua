-- ---------------------------------------------------------------------------------
-- Name: UIWidgeAddCampCell
-- Desc: 添加帮会cell
-- Prefab:WidgeCrewPlayerCell
-- ---------------------------------------------------------------------------------

local UIWidgeAddCampCell = class("UIWidgeAddCampCell")

function UIWidgeAddCampCell:OnEnter(nTongID, bShowToggle, szFunc)
    if not self.bInit then
        self:BindUIEvent()
        self:RegEvent()
        self.bInit = true
        self.nFactionWidth = UIHelper.GetWidth(self.WidgeCampFactionCell)
        self.nRootWidth = UIHelper.GetWidth(self._rootNode)
    end
    self.nTongID = nTongID
    self.bShowToggle = bShowToggle or false
    self.szFunc = szFunc
    self:UpdateInfo()
end

function UIWidgeAddCampCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgeAddCampCell:BindUIEvent()
    UIHelper.BindUIEvent(self.TogSelect, EventType.OnSelectChanged, function(_, bSelect)
        if self.szFunc then
            self.szFunc(bSelect)
        end
    end)
end

function UIWidgeAddCampCell:RegEvent()
    
end

function UIWidgeAddCampCell:UnRegEvent()

end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
function UIWidgeAddCampCell:UpdateInfo()
    local tbInfo = CommandBaseData.GetTongDataByID(self.nTongID)
    UIHelper.SetString(self.LableFactionName, UIHelper.GBKToUTF8(tbInfo.szTongName))
    UIHelper.SetString(self.LablePlayerName, UIHelper.GBKToUTF8(tbInfo.szMasterName))
    UIHelper.SetString(self.LabelScore, UIHelper.GBKToUTF8(tbInfo.nKey) .. g_tStrings.STR_COMMAND_FEN)

    local tbCastleInfo = CommandBaseData.GetTongCastleInfoByName(szName)
    local szCastleName = CommandBaseData.GetCastleNameByID(nTongID)
    UIHelper.SetString(self.LableCity, UIHelper.GBKToUTF8(szCastleName))

    self:SetDeleteToggle(self.bShowToggle)
end

function UIWidgeAddCampCell:SetDeleteToggle(bOpen)
    self.bOpenDelTog = bOpen
    self:UpdateToggleVis()
end

function UIWidgeAddCampCell:UpdateToggleVis()
    UIHelper.SetVisible(self.TogSelect, self.bOpenDelTog)
    local nWidth = self.bOpenDelTog and self.nFactionWidth or self.nRootWidth
    UIHelper.SetWidth(self.WidgeCampFactionCell, nWidth)
end

return UIWidgeAddCampCell