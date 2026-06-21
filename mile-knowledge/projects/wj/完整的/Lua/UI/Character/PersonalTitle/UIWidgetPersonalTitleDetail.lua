-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIWidgetPersonalTitleDetail
-- Date: 2023-03-14 17:41:58
-- Desc: PanelPersonalTitle的WidgetAnchorRight
-- ---------------------------------------------------------------------------------

local UIWidgetPersonalTitleDetail = class("UIWidgetPersonalTitleDetail")


function UIWidgetPersonalTitleDetail:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    UIHelper.SetSwallowTouches(self.ScollViewRight, false)
end

function UIWidgetPersonalTitleDetail:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetPersonalTitleDetail:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnSendToChat, EventType.OnClick, function()
        if self.dwID then
            local bPrefix = self.nType ~= DESIGNATION_TYPE.POSTFIX
            ChatHelper.SendDesignationToChat(self.dwID, bPrefix, UI_GetPlayerForceID())
        end
    end)
    UIHelper.BindUIEvent(self.BtnGoto, EventType.OnClick, function()
        DesignationMgr.ShowEffectView(self.szName)
    end)
end

function UIWidgetPersonalTitleDetail:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetPersonalTitleDetail:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIWidgetPersonalTitleDetail:UpdateInfo(tData, bLink, bInit)
    if not tData then
        if bInit then
            self:SetVisible(false)
        end
        return
    end
    self:SetVisible(true)

    self:InitConfigAndInfo(tData)
    self:UpdateTitle(tData)
    self:UpdateTypeAndCDTime(tData)
    self:UpdateState(tData, bLink)
    self:UpdateSource(tData)
    self:UpdateDesc(tData)
    self:UpdateImage(tData)

    UIHelper.CascadeDoLayoutDoWidget(self.ScollViewRight, true, true)
    UIHelper.ScrollViewDoLayout(self.ScollViewRight)
    UIHelper.ScrollToTop(self.ScollViewRight, 0)
end

function UIWidgetPersonalTitleDetail:UpdateTitle(tData)
    local szName = tData.szName

    local bHave = tData.bHave --拥有
    local nQuality = tData.nQuality --品质

    self.scriptQualityBar = self.scriptQualityBar or UIHelper.AddPrefab(PREFAB_ID.WidgetQualityBar, self.WidgetQualityBar)
    self.scriptQualityBar:OnEnter(nQuality + 1)

    local szQualityImgPath = HorseTitleQualityBGColor[nQuality]
    UIHelper.SetSpriteFrame(self.ImgPersonalTitleAttribute, szQualityImgPath)

    UIHelper.SetString(self.LabelPersonalTitleAttribute, szName)
    UIHelper.SetVisible(self.LabelPersonalTitleState, bHave)

    UIHelper.SetVisible(self.BtnSendToChat, self.nType ~= DESIGNATION_TYPE.COURTESY)
end

function UIWidgetPersonalTitleDetail:UpdateTypeAndCDTime(tData)
    local dwID = tData.dwID
    local nType = tData.nType

    local szType = "" --称号类型
    local szCDTime = "" --调息时间

    if nType == DESIGNATION_TYPE.COURTESY then
        szType = "门派称号"
    else
        local bPrefix = nType ~= DESIGNATION_TYPE.POSTFIX
        local aInfo = self.aInfo
        if not aInfo then
            return
        end

        if bPrefix then
            if aInfo.nType == DESIGNATION_PREFIX_TYPE.WORLD_DESIGNATION then
                szType = "世界称号"
            elseif aInfo.nType == DESIGNATION_PREFIX_TYPE.MILITARY_RANK_DESIGNATION then
                szType = "战阶称号"
            else
                szType = "称号前缀"
            end
        else
            szType = "称号后缀"
        end

        if aInfo.dwCoolDownID ~= 0 then
            local dwCD = GetCoolDownFrame(aInfo.dwCoolDownID)
            if dwCD and dwCD ~= 0 then
                local szTime = TimeLib.GetTimeText(dwCD, true, false, true)
                --szCDTime = FormatString(g_tStrings.DESGNATION_NEED_REST, szTime)
                szCDTime = szTime .. "调息"
            end
        end
    end

    UIHelper.SetString(self.LabelTime, szType)
    UIHelper.SetString(self.LabelTime1, szCDTime)
    UIHelper.SetVisible(self.LabelTime1, szCDTime ~= "")
end

function UIWidgetPersonalTitleDetail:UpdateState(tData, bLink)
    local pPlayer = GetClientPlayer()
	if not pPlayer then
		return
	end

    local dwID = tData.dwID
    local nType = tData.nType

    local bHave = tData.bHave --拥有
    local bDisable = tData.bDisable --唯一
    local bTimeLimit = tData.bTimeLimit --限时
    local bIsEffect = tData.bIsEffect --特效

    local szLeftTime = "" --剩余时间

    if nType ~= DESIGNATION_TYPE.COURTESY then
        local bPrefix = nType ~= DESIGNATION_TYPE.POSTFIX
        local aInfo = self.aInfo
        if not aInfo then
            return
        end

        if bLink or not bHave then
            if aInfo.nOwnDuration > 0 then
                local szTime = TimeLib.GetTimeText(aInfo.nOwnDuration, false, true, true)
                szLeftTime = szTime .. "后消失" --FormatString(g_tStrings.DESGNATION_OWN_TIME, szTime)
            end
        else
            local nEndTime
            if dwID ~= 0 and bHave then
                nEndTime = bPrefix and pPlayer.GetDesignationPrefixEndTime(dwID) or pPlayer.GetDesignationPostfixEndTime(dwID)
            end
            if nEndTime and nEndTime > 0 then
                local nDelta = nEndTime - GetCurrentTime()
                if nDelta < 0 then
                    nDelta = 0
                end
                local szTime = TimeLib.GetTimeText(nDelta, false, true, true)
                szLeftTime = szTime .. "后消失" --FormatString(g_tStrings.DESGNATION_DISSAPPEAR_TIME, szTime)
            end
        end
    end

    local bHaveState = bDisable or bTimeLimit or bIsEffect
    UIHelper.SetVisible(self.LabelState, bDisable)
    UIHelper.SetVisible(self.LabelState01, bTimeLimit)
    UIHelper.SetVisible(self.LabelState02, bIsEffect)
    UIHelper.SetVisible(self.LayoutState, bHaveState)

    if bTimeLimit then
        if szLeftTime ~= "" then
            if not bHave then
                szLeftTime = "获得" .. szLeftTime
            end
            UIHelper.SetString(self.LabelState01, "限时：" .. szLeftTime)
        else
            UIHelper.SetString(self.LabelState01, "限时：一定时间后消失")
        end
    end

    local bShowEffectBtn = false
    if bIsEffect then
        if bHave then
            if DesignationMgr.GetDesignationEffectPage(tData.szName) then
                bShowEffectBtn = true
                UIHelper.SetString(self.LabelState02, "特效：已解锁特效")
            else
                UIHelper.SetString(self.LabelState02, "特效：应用称号后有特效表现")
            end
        else
            UIHelper.SetString(self.LabelState02, "特效：获得称号后可以穿戴特效")
        end
    end
    UIHelper.SetVisible(self.BtnGoto, bShowEffectBtn)
end

function UIWidgetPersonalTitleDetail:UpdateSource(tData)
    local nType = tData.nType
    local szSource = "" --获得方式

    if nType ~= DESIGNATION_TYPE.COURTESY then
        local aDesignation = self.aDesignation
        if not aDesignation then
            return
        end

        if aDesignation.dwAchievement ~= 0 then
            local aAchievement = g_tTable.Achievement:Search(aDesignation.dwAchievement)
            if aAchievement then
                 --完成XX可获得
                szSource = g_tStrings.DESGNATION_AHIVEMENT_GET .. UIHelper.GBKToUTF8(aAchievement.szName) .. "可以获得该称号" --g_tStrings.DESGNATION_AHIVEMENT_GET1
            end
        end

        if aDesignation.dwTableIndex ~= 0 then
            local itemInfo = ItemData.GetItemInfo(5, aDesignation.dwTableIndex)
            if itemInfo then
                if szSource ~= "" then
                    szSource = szSource .. "\n"
                end
                --使用物品XX可获得
                local szItemName = UIHelper.GBKToUTF8(ItemData.GetItemNameByItemInfo(itemInfo))
                local r, g, b = GetItemFontColorByQuality(itemInfo.nQuality)
                local szText = GetFormatText("[" .. szItemName .. "]", nil, r, g, b)
                szSource = szSource .. g_tStrings.DESGNATION_USE_ITEM_GET .. szText .. "可以获得该称号" --g_tStrings.DESGNATION_USE_ITEM_GET1
            end
        end
    end

    UIHelper.SetVisible(self.LayoutSource, szSource ~= "")
    UIHelper.SetRichText(self.RichTextSource, UIHelper.AttachTextColor(szSource, FontColorID.Text_Level1))
end

function UIWidgetPersonalTitleDetail:UpdateDesc(tData)
    local pPlayer = GetClientPlayer()
	if not pPlayer then
		return
	end

    local nType = tData.nType
    local szBuffDesc
    local szDesc

    if nType == DESIGNATION_TYPE.COURTESY then
        local nGeneration = tData.dwID
        local nForceID = pPlayer.dwForceID
        local aGen = g_tTable.Designation_Generation:Search(nForceID, nGeneration)
        if aGen and not string.is_nil(aGen.szDesc) then
            szDesc = UIHelper.GBKToUTF8(aGen.szDesc)
            --szDesc = string.pure_text(szDesc)
            szDesc = ParseTextHelper.ParseNormalText(szDesc, false)
        end
    else
        local aInfo, aDesignation = self.aInfo, self.aDesignation
        if not aDesignation or not aInfo then
            return
        end

        if aInfo.dwBuffID ~= 0 and aInfo.nBuffLevel ~= 0 then
            szBuffDesc = BuffMgr.GetBuffDesc(aInfo.dwBuffID, aInfo.nBuffLevel)
            if not string.is_nil(szBuffDesc) then
                -- szBuffDesc = szBuffDesc .. g_tStrings.STR_FULL_STOP .. "\n"
                szBuffDesc = UIHelper.AttachTextColor(szBuffDesc, FontColorID.ImportantGreen)
            end
        end

        if not string.is_nil(aDesignation.szDesc) then
            szDesc = UIHelper.GBKToUTF8(aDesignation.szDesc)
            --szDesc = string.pure_text(szDesc)
            szDesc = ParseTextHelper.ParseNormalText(szDesc, false)
        end
    end

    --szDesc = szDesc and UIHelper.AttachTextColor(szDesc, FontColorID.ImportantYellow)

    UIHelper.SetVisible(self.LayoutBuff, not string.is_nil(szBuffDesc))
    UIHelper.SetRichText(self.RichTextBuff, szBuffDesc)
    UIHelper.SetVisible(self.LayoutAttribute, not string.is_nil(szDesc))
    UIHelper.SetRichText(self.RichTextAttribute, szDesc)
end

function UIWidgetPersonalTitleDetail:UpdateImage(tData)
    local nType = tData.nType

    local bIsEffect = tData.bIsEffect --特效
    local szImagePath

    if nType ~= DESIGNATION_TYPE.COURTESY then
        local aDesignation = self.aDesignation
        if not aDesignation then
            return
        end

        if bIsEffect then
            szImagePath = aDesignation.szImagePath
        end
    end

    if szImagePath then
        szImagePath = string.gsub(szImagePath, "ui[/\\]Image", "Resource")
        szImagePath = string.gsub(szImagePath, ".[Tt]ga", ".png")
        UIHelper.SetVisible(self.LayoutShow, true)
        UIHelper.SetTexture(self.ImgShow, szImagePath)
    else
        UIHelper.SetVisible(self.LayoutShow, false)
    end
end

function UIWidgetPersonalTitleDetail:InitConfigAndInfo(tData)
    local dwID = tData.dwID
    local nType = tData.nType

    if self.dwID == dwID and self.nType == nType then
        return
    end
    self.dwID = dwID
    self.nType = nType
    self.szName = tData.szName

    local aInfo, aDesignation = nil, nil
    if nType ~= DESIGNATION_TYPE.COURTESY then
        local bPrefix = nType ~= DESIGNATION_TYPE.POSTFIX
        if bPrefix then
            if dwID ~= 0 then
                aInfo = GetDesignationPrefixInfo(dwID)
            end
            aDesignation = Table_GetDesignationPrefixByID(dwID, UI_GetPlayerForceID())
        else
            if dwID ~= 0 then
                aInfo = GetDesignationPostfixInfo(dwID)
            end
            aDesignation = g_tTable.Designation_Postfix:Search(dwID)
        end
    end
    self.aInfo = aInfo
    self.aDesignation = aDesignation
end

function UIWidgetPersonalTitleDetail:SetVisible(bVisible)
    UIHelper.SetVisible(self.WidgetEmpty1, not bVisible)
    UIHelper.SetVisible(self.ScollViewRight, bVisible)
    UIHelper.SetVisible(self.WidgetPersonalTitleAttribute, bVisible)
end

-- function UIWidgetPersonalTitleDetail:UpdateDesignationDetail(tData, bLink)
--     local pPlayer = GetClientPlayer()
-- 	if not pPlayer then
-- 		return
-- 	end

--     local dwID = tData.dwID
--     local nType = tData.nType
--     local szName = tData.szName

--     local bHave = tData.bHave --拥有
--     local nQuality = tData.nQuality --品质
--     local bDisable = tData.bDisable --唯一
--     local bTimeLimit = tData.bTimeLimit --限时
--     local bIsEffect = tData.bIsEffect --特效

--     local szType = "" --称号类型
--     local szSource = "" --获得方式
--     local szDesc = "" --描述
--     local szCDTime = "" --调息时间
--     local szLeftTime = "" --剩余时间
--     local szImagePath

--     if nType == DESIGNATION_TYPE.COURTESY then
--         local nGeneration = tData.dwID
--         local nForceID = pPlayer.dwForceID
--         local aGen = g_tTable.Designation_Generation:Search(nForceID, nGeneration)
--         szType = "门派称号"
--         if aGen and aGen.szDesc then
--             szDesc = UIHelper.GBKToUTF8(aGen.szDesc)
--         end
--     else
--         local bPrefix = nType ~= DESIGNATION_TYPE.POSTFIX
--         local aInfo, aDesignation = nil, nil
--         if bPrefix then
--             if dwID ~= 0 then
--                 aInfo = GetDesignationPrefixInfo(dwID)
--             end
--             aDesignation = g_tTable.Designation_Prefix:Search(dwID)
--         else
--             if dwID ~= 0 then
--                 aInfo = GetDesignationPostfixInfo(dwID)
--             end
--             aDesignation = g_tTable.Designation_Postfix:Search(dwID)
--         end
--         if not aDesignation or not aInfo then
--             return
--         end

--         if bPrefix then
--             if aInfo.nType == DESIGNATION_PREFIX_TYPE.WORLD_DESIGNATION then
--                 szType = "世界称号"
--             elseif aInfo.nType == DESIGNATION_PREFIX_TYPE.MILITARY_RANK_DESIGNATION then
--                 szType = "战阶称号"
--             else
--                 szType = "称号前缀"
--             end
--         else
--             szType = "称号后缀"
--         end

--         if aDesignation.dwAchievement ~= 0 then
--             local aAchievement = g_tTable.Achievement:Search(aDesignation.dwAchievement)
--             if aAchievement then
--                  --完成XX可获得
--                 szSource = g_tStrings.DESGNATION_AHIVEMENT_GET .. UIHelper.GBKToUTF8(aAchievement.szName) .. "可以获得该称号" --g_tStrings.DESGNATION_AHIVEMENT_GET1
--             end
--         end

--         if aDesignation.dwTableIndex ~= 0 then
--             local itemInfo = ItemData.GetItemInfo(5, aDesignation.dwTableIndex)
--             if itemInfo then
--                 if szSource ~= "" then
--                     szSource = szSource .. "\n"
--                 end
--                 --使用物品XX可获得
--                 local szItemName = UIHelper.GBKToUTF8(ItemData.GetItemNameByItemInfo(itemInfo))
--                 local r, g, b = GetItemFontColorByQuality(itemInfo.nQuality)
--                 local szText = GetFormatText("[" .. szItemName .. "]", nil, r, g, b)
--                 szSource = szSource .. g_tStrings.DESGNATION_USE_ITEM_GET .. szText .. "可以获得该称号" --g_tStrings.DESGNATION_USE_ITEM_GET1
--             end
--         end

--         if aInfo.dwBuffID ~= 0 and aInfo.nBuffLevel ~= 0 then
--             local szBuffDesc = BuffMgr.GetBuffDesc(aInfo.dwBuffID, aInfo.nBuffLevel)
--             if szBuffDesc and szBuffDesc ~= "" then
--                 szDesc = szBuffDesc .. g_tStrings.STR_FULL_STOP .. "\n"
--             end
--         end

--         if bIsEffect then
--             szImagePath = aDesignation.szImagePath
--         end

--         if aDesignation.szDesc and aDesignation.szDesc ~= "" then
--             szDesc = szDesc .. UIHelper.GBKToUTF8(aDesignation.szDesc)
--         end

--         if aInfo.dwCoolDownID ~= 0 then
--             local dwCD = GetCoolDownFrame(aInfo.dwCoolDownID)
--             if dwCD and dwCD ~= 0 then
--                 local szTime = TimeLib.GetTimeText(dwCD, true, false, true)
--                 --szCDTime = FormatString(g_tStrings.DESGNATION_NEED_REST, szTime)
--                 szCDTime = szTime .. "调息"
--             end
--         end

--         if bLink or not bHave then
--             if aInfo.nOwnDuration > 0 then
--                 local szTime = TimeLib.GetTimeText(aInfo.nOwnDuration, false, true, true)
--                 szLeftTime = FormatString(g_tStrings.DESGNATION_OWN_TIME, szTime)
--             end
--         else
--             local nEndTime
--             if dwID ~= 0 and bHave then
--                 nEndTime = bPrefix and pPlayer.GetDesignationPrefixEndTime(dwID) or pPlayer.GetDesignationPostfixEndTime(dwID)
--             end
--             if nEndTime and nEndTime > 0 then
--                 local nDelta = nEndTime - GetCurrentTime()
--                 if nDelta < 0 then
--                     nDelta = 0
--                 end
--                 local szTime = TimeLib.GetTimeText(nDelta, false, true, true)
--                 szLeftTime = FormatString(g_tStrings.DESGNATION_DISSAPPEAR_TIME, szTime)
--             end
--         end
--     end

--     local szQualityImgPath = HorseTitleQualityBGColor[nQuality]
--     UIHelper.SetSpriteFrame(self.ImgPersonalTitleAttribute, szQualityImgPath)

--     UIHelper.SetString(self.LabelPersonalTitleAttribute, szName)
--     UIHelper.SetVisible(self.LabelPersonalTitleState, bHave)
--     UIHelper.SetString(self.LabelTime, szType)
--     UIHelper.SetString(self.LabelTime1, szCDTime)
--     UIHelper.SetVisible(self.LabelTime1, szCDTime ~= "")

--     local bHaveState = bDisable or bTimeLimit or bIsEffect
--     UIHelper.SetVisible(self.LabelState, bDisable)
--     UIHelper.SetVisible(self.LabelState01, bTimeLimit)
--     UIHelper.SetVisible(self.LabelState02, bIsEffect)
--     UIHelper.SetVisible(self.LayoutState, bHaveState)
--     if bTimeLimit then
--         if szLeftTime ~= "" then
--             if not bHave then
--                 szLeftTime = "获得" .. szLeftTime
--             end
--             UIHelper.SetString(self.LabelState01, "限时：" .. szLeftTime)
--         else
--             UIHelper.SetString(self.LabelState01, "一定时间后消失")
--         end
--     end

--     UIHelper.SetVisible(self.LayoutSource, szSource ~= "")
--     UIHelper.SetRichText(self.RichTextSource, szSource)

--     -- szDesc = string.pure_text(szDesc)
--     szDesc = ParseTextHelper.ParseNormalText(szDesc, false)
--     UIHelper.SetVisible(self.LayoutAttribute, szDesc ~= "")
--     UIHelper.SetString(self.LabelAttribute, szDesc)

--     if szImagePath then
--         szImagePath = string.gsub(szImagePath, "ui[/\\]Image", "Resource")
--         szImagePath = string.gsub(szImagePath, ".[Tt]ga", ".png")
--         UIHelper.SetVisible(self.LayoutShow, true)
--         UIHelper.SetTexture(self.ImgShow, szImagePath)
--     else
--         UIHelper.SetVisible(self.LayoutShow, false)
--     end

--     UIHelper.CascadeDoLayoutDoWidget(self.ScollViewRight, true, true)
--     UIHelper.ScrollViewDoLayout(self.ScollViewRight)
--     UIHelper.ScrollToTop(self.ScollViewRight, 0)
-- end


return UIWidgetPersonalTitleDetail