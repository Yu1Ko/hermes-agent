-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIWidgetLabelCityContribute
-- Date: 2023-08-01 11:35:11
-- Desc: UIWidgetLabelCityContribute 据点归属界面-行
-- ---------------------------------------------------------------------------------

local UIWidgetLabelCityContribute = class("UIWidgetLabelCityContribute")

local CUR_CASTLE_COLOR = cc.c3b(255, 226, 110)

function UIWidgetLabelCityContribute:OnEnter(nRankID, szCastleName, bCurCastle, tRecord, tCastle)
    self.nRankID = nRankID
    self.szCastleName = szCastleName
    self.bCurCastle = bCurCastle
    self.tRecord = tRecord
    self.tCastle = tCastle

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIWidgetLabelCityContribute:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetLabelCityContribute:BindUIEvent()
    
end

function UIWidgetLabelCityContribute:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetLabelCityContribute:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetLabelCityContribute:UpdateInfo()
    local nRankID = self.nRankID or 0
    local szCastleName = self.szCastleName --GBK
    local bCurCastle = self.bCurCastle
    local tRecord = self.tRecord or {}
    local tCastle = self.tCastle or {}

    local szTongName = UIHelper.GBKToUTF8(tRecord.szTongName or "")
    local nTitlePoint = tRecord.nTitlePoint or 0

    UIHelper.SetString(self.LabelFactionMessage1, nRankID)
    UIHelper.SetString(self.LabelFactionMessage2, szTongName)
    UIHelper.SetString(self.LabelFactionMessage3, nTitlePoint)

    if szCastleName then
        szCastleName = UIHelper.GBKToUTF8(szCastleName)
        UIHelper.SetString(self.LabelFactionMessage4, szCastleName)

        --等于页面所对应的据点，则字体变色
        if bCurCastle then
            UIHelper.SetColor(self.LabelFactionMessage4, CUR_CASTLE_COLOR)
        end
    else
        UIHelper.SetString(self.LabelFactionMessage4, g_tStrings.STR_NONE)
    end

    local szReward = g_tStrings.STR_NONE
    if tCastle.nState == 2 and nRankID >= 1 and nRankID <= 3 and tCastle.nAddPiece > 0 then
        -- local dwTabType, dwIndex = 5, 71556
        -- local ItemInfo = GetItemInfo(dwTabType, dwIndex)
        -- if ItemInfo then
        --     local itemScript = UIMgr.AddPrefab(PREFAB_ID.WidgetItem_44, self.LabelFactionMessage5)
        --     itemScript:OnInitWithTabID(dwTabType, dwIndex, tCastle.nAddPiece)
        -- end
        local szImgPath = "UIAtlas2_CampMap_Icon_Img_Exploit"
        szReward = string.format("<img src='%s' width='30' height='30'/>×%d", szImgPath, tCastle.nAddPiece)
    end
    UIHelper.SetRichText(self.LabelFactionMessage5, szReward)
end


return UIWidgetLabelCityContribute