-- ---------------------------------------------------------------------------------
-- Author: jiayuran
-- Name: UIWidgetFengYunLuDesignationCell
-- ---------------------------------------------------------------------------------

---@class UIWidgetFengYunLuDesignationCell
local UIWidgetFengYunLuDesignationCell = class("UIWidgetFengYunLuDesignationCell")

function UIWidgetFengYunLuDesignationCell:OnEnter(nID, dwForceID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true

        self.nID = nID
        self.dwForceID = dwForceID
    end

    self:UpdateInfo()
end

function UIWidgetFengYunLuDesignationCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetFengYunLuDesignationCell:BindUIEvent()
end

function UIWidgetFengYunLuDesignationCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetFengYunLuDesignationCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIWidgetFengYunLuDesignationCell:UpdateInfo()
    local aInfo, aDesignation = nil, nil
    aInfo = GetDesignationPrefixInfo(self.nID)
    aDesignation = Table_GetDesignationPrefixByID(self.nID, tonumber(self.dwForceID))

    local szDesignation = UIHelper.GBKToUTF8(aDesignation.szName)
    local r, g, b = GetItemFontColorByQuality(aDesignation.nQuality, false)
    UIHelper.SetColor(self.LabelTitle, cc.c3b(r, g, b))
    UIHelper.SetString(self.LabelTitle, szDesignation)

    local szWorld = nil
    if aInfo and aInfo.nType == DESIGNATION_PREFIX_TYPE.WORLD_DESIGNATION then
        szWorld = g_tStrings.DESGNATION_WORLD
    elseif aInfo and aInfo.nType == DESIGNATION_PREFIX_TYPE.MILITARY_RANK_DESIGNATION then
        szWorld = g_tStrings.DESGNATION_TITLE
    else
        szWorld = g_tStrings.DESGNATION_PREFIX
    end
    UIHelper.SetString(self.LabelWorldTitle, szWorld)

    local nType = aInfo.nType
    local szDesc = "" --描述

    if nType == DESIGNATION_TYPE.COURTESY then
        local nGeneration = tData.dwID
        local nForceID = pPlayer.dwForceID
        local aGen = g_tTable.Designation_Generation:Search(nForceID, nGeneration)
        if aGen and aGen.szDesc then
            szDesc = UIHelper.GBKToUTF8(aGen.szDesc)
        end
    else
        if not aDesignation or not aInfo then
            return
        end

        if aInfo.dwBuffID ~= 0 and aInfo.nBuffLevel ~= 0 then
            local szBuffDesc = BuffMgr.GetBuffDesc(aInfo.dwBuffID, aInfo.nBuffLevel)
            -- if szBuffDesc and szBuffDesc ~= "" then
            --     szDesc = szBuffDesc .. g_tStrings.STR_FULL_STOP .. "\n"
            -- end
        end

        if aDesignation.szDesc and aDesignation.szDesc ~= "" then
            szDesc = szDesc .. UIHelper.GBKToUTF8(aDesignation.szDesc)
        end
        szDesc = string.pure_text(szDesc)
    end
    UIHelper.SetString(self.LabelIntroduce, szDesc)
    
    UIHelper.LayoutDoLayout(self.WidgetTitle)
end

return UIWidgetFengYunLuDesignationCell