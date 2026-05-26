local UIMainCityBuffCell = class("UIMainCityBuffCell")
local BUFF_ACT912 = 28095
local BUFF_ACT912_LEVEL = 1

function UIMainCityBuffCell:OnEnter()
    UIHelper.SetTouchDownHideTips(self.BtnDel, false)
    UIHelper.BindUIEvent(self.BtnDel, EventType.OnClick, function()
        if self.nIndex and self.tb then
            Event.Dispatch("PLAYER_REMOVE_BUFF", self.tb)
            GetClientPlayer().CancelBuff(self.nIndex)
            self:SetBuffDeleted()
        end
    end)
    
    Event.Reg(self, "OnAddtionalBuffDescribe", function(szMessage, nBuffID, nBuffLevel)
        if self.tb and self.tb.dwID == nBuffID and self.tb.nLevel == nBuffLevel then
            local tbAddtionalBuffDescribe = {
                szMessage = UIHelper.GBKToUTF8(szMessage),
                nBuffID = nBuffID,
                nBuffLevel = nBuffLevel,
            }
            self.tbAddtionalBuffDescribe = tbAddtionalBuffDescribe
            local tbTipsList = Storage.XiaoChengWuBuffTips.tbTipsList
            if not tbTipsList[nBuffID] or tbTipsList[nBuffID] ~= tbAddtionalBuffDescribe.szMessage then
                Storage.XiaoChengWuBuffTips.tbTipsList[nBuffID] = tbAddtionalBuffDescribe.szMessage
                Storage.XiaoChengWuBuffTips.Dirty()
            end

            local szDesc = BuffMgr.GetBuffDesc(self.tb.dwID, self.tb.nLevel)
            if szDesc and Table_IsBuffDescAddPeriod(self.tb.dwID, self.tb.nLevel) then
                szDesc = szDesc .. g_tStrings.STR_FULL_STOP
            end

            UIHelper.SetRichText(
                self.RichTextBuffContent,
                szDesc .. string.format("\n<color=#ffe26e>%s</c>", tbAddtionalBuffDescribe.szMessage)
            )

            UIHelper.LayoutDoLayout(self._rootNode)
            Event.Dispatch("MAIN_CITY_BUFF_TIP_NEED_LAYOUT")
        end
    end)
end

function UIMainCityBuffCell:OnExit()
    self.nIndex = nil
    self.tb = nil
end

function UIMainCityBuffCell:UpdateInfo(tb, bShowTime, bLast, bShowCancel, bDeleted, bExpired, bNeedUpdateBuffTips)
    self.tb = tb
    
    local szName = BuffMgr.GetBuffName(tb.dwID, tb.nLevel)
    local szDesc = BuffMgr.GetBuffDesc(tb.dwID, tb.nLevel)
    if szDesc and Table_IsBuffDescAddPeriod(tb.dwID, tb.nLevel) then
        szDesc = szDesc..g_tStrings.STR_FULL_STOP
    end

    local szIcon = TabHelper.GetBuffIconPath(tb.dwID, tb.nLevel)

    UIHelper.SetString(self.LabelBuffName, szName, 7)
    --UIHelper.SetString(self.LabelBuffContent, szDesc)

    local catalog = BuffMgr.GetBuffCatalog(tb.dwID, tb.nLevel)
    if catalog.nID == 0 then
        local tbTipList = Storage.XiaoChengWuBuffTips.tbTipsList
        local bHasLocalAdditional = self.tbAddtionalBuffDescribe
            and self.tbAddtionalBuffDescribe.nBuffID == tb.dwID
            and self.tbAddtionalBuffDescribe.nBuffLevel == tb.nLevel

        local szAdditionalMsg = nil
        if bHasLocalAdditional then
            szAdditionalMsg = self.tbAddtionalBuffDescribe.szMessage
        else
            szAdditionalMsg = tbTipList and tbTipList[tb.dwID] or nil
        end

        if szAdditionalMsg and szAdditionalMsg ~= "" then
            UIHelper.SetRichText(self.RichTextBuffContent, szDesc .. string.format("\n<color=#ffe26e>%s</c>", szAdditionalMsg))
        else
            UIHelper.SetRichText(self.RichTextBuffContent, szDesc)
        end
    else
        local bDispel = BuffMgr.Buffer_IsDispelMobile(tb.dwID, tb.nLevel)
        if bDispel then --可被驱散
            UIHelper.SetRichText(self.RichTextBuffContent, szDesc.."<color=#ffe26e>（可被驱散）</c>")
        else
            UIHelper.SetRichText(self.RichTextBuffContent, szDesc)
        end
    end
    if tb.nStackNum > 1 then
        UIHelper.SetVisible(self.LabelBuffLevel, true)
        UIHelper.SetString(self.LabelBuffLevel, tb.nStackNum)
    else
        UIHelper.SetVisible(self.LabelBuffLevel, false)
    end

    UIHelper.SetVisible(self.LabelBuffTime, true)
    if bShowTime then
        if not bDeleted and not bExpired then
            local nTime  = tb.nEndFrame and BuffMgr.GetLeftFrame(tb) or tb.nLeftTime
            local szTime = tb.nEndFrame and UIHelper.GetHeightestTimeText(nTime, true) or UIHelper.GetTimeHourText(nTime, false)
            UIHelper.SetString(self.LabelBuffTime, szTime)
            if nTime == 0 then
                Event.Dispatch("UPDATE_EXPIRED_BUFF", tb)
                self:SetBuffExpired()
            end
        end
    else
        UIHelper.SetString(self.LabelBuffTime, "")
    end

    if bDeleted then
        self:SetBuffDeleted()
    elseif bExpired then
        self:SetBuffExpired()
    end

    UIHelper.SetVisible(self.ImgLine, not bLast)

    if szIcon then
        local szPath
        local prefix = "Resource/"
        if string.find(szIcon, "^" .. prefix) then
            szPath = szIcon
        else
            szPath = szIcon and string.format("Resource/icon/%s", szIcon)
        end
        if szPath and Lib.IsFileExist(szPath) then
            UIHelper.SetTexture(self.ImgBuffIcon, szPath, false)
            --UIHelper.SetSpriteFrame(self.ImgBuffIcon, szIcon)
        end
    end

    UIHelper.SetVisible(self.BtnDel, false)
    -- UIHelper.SetPositionX(self.LabelBuffTime, 201.43)
    if bShowCancel and (not bDeleted and not bExpired) then
        if tb.bCanCancel or BuffMgr.Buffer_IsDispel(tb.dwID, tb.nLevel) then
            self.nIndex = tb.nIndex
            self.tb = tb
            UIHelper.SetVisible(self.BtnDel, true)
            -- UIHelper.SetPositionX(self.LabelBuffTime, 201.43 - 5)
        end
    end

    -- 如果是吃鸡技能buff需要替换样式
    local bTreasureBFSkillBuff = false
    if TreasureBattleFieldSkillData.InSkillMap() then
        local nSkillID = TreasureBattleFieldSkillData.GetBuffSkillID(tb.dwID)
        if nSkillID then
            bTreasureBFSkillBuff = true
            local node = UIHelper.GetChildByName(self.widgetSkill, "WidgetSkillCell")
            local script
            if not node then
                script = UIHelper.AddPrefab(PREFAB_ID.WidgetSkillCell1, self.widgetSkill)
                script:SetSelectEnable(false)
                UIHelper.SetAnchorPoint(script._rootNode, 0.5, 0.5)
            else
                script = UIHelper.GetBindScript(node)
            end
            script:UpdateInfo(nSkillID)
        end
    end
    UIHelper.SetVisible(self.widgetSkill, bTreasureBFSkillBuff)
    UIHelper.SetVisible(self.ImgBuffFrame, not bTreasureBFSkillBuff)
    UIHelper.SetVisible(self.ImgBuffIcon, not bTreasureBFSkillBuff)
    
    if tb.dwID and tb.dwID == BUFF_ACT912 and tb.nLevel and tb.nLevel == BUFF_ACT912_LEVEL and not self.bCheck and bNeedUpdateBuffTips then
        RemoteCallToServer("On_Activity_MbGetXCWNum", tb.dwID, tb.nLevel)
        self.bCheck = true
    end
end

function UIMainCityBuffCell:SetBuffDeleted()
    UIHelper.SetString(self.LabelBuffTime, "已过期")
    UIHelper.SetVisible(self.BtnDel, false)
end

function UIMainCityBuffCell:SetBuffExpired()
    UIHelper.SetString(self.LabelBuffTime, "已过期")
    UIHelper.SetVisible(self.BtnDel, false)
end

function UIMainCityBuffCell:UpdateMatrix()
    UIHelper.SetVisible(self.LabelBuffTime, false)
    UIHelper.SetVisible(self.BtnDel, false)
    local szTitle = MatrixData.GetTitle()
    local szDesc = MatrixData.GetTips()
    local szPath = MatrixData.GetImg()

    if szPath and Lib.IsFileExist(szPath) then
        UIHelper.SetTexture(self.ImgBuffIcon, szPath)
    end
    UIHelper.SetVisible(self.LabelBuffLevel, false)
    UIHelper.SetString(self.LabelBuffName, szTitle)
    UIHelper.SetRichText(self.RichTextBuffContent, szDesc)
    UIHelper.SetVisible(self.ImgLine, false)
    UIHelper.LayoutDoLayout(self._rootNode)
end

function UIMainCityBuffCell:ShowImgLine(bShow)
    UIHelper.SetVisible(self.ImgLine, bShow)
    UIHelper.LayoutDoLayout(self._rootNode)
end


return UIMainCityBuffCell