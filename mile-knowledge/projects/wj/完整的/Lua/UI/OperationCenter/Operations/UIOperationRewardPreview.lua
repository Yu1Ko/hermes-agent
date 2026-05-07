-- ---------------------------------------------------------------------------------
-- Author: huqing
-- Name: UIOperationRewardPreview
-- Date: 2026-04-14 20:29:04
-- Desc: 江湖快报 - 奖励更新
-- ---------------------------------------------------------------------------------


--[[
self.ToggleSelect  = self.ToggleSelect
self.ImgQualityBg  = self.ImgQualityBg
self.ImgItem       = self.ImgItem
self.LabelItemName = self.LabelItemName
self.ImgTag        = self.ImgTag
self.LabelType     = self.LabelType
]]

local UIOperationRewardPreview = class("UIOperationRewardPreview")

function UIOperationRewardPreview:OnEnter(nOperationID, nID, tComponentContext)
    self.nOperationID = nOperationID
    self.nID = nID
    self.tComponentContext = tComponentContext

    self.scriptTop = self.tComponentContext and self.tComponentContext.tScriptLayoutTop and self.tComponentContext.tScriptLayoutTop[1]
    UIHelper.SetVisible(self.scriptTop.ScrollViewTopAnchoreContentList, false)
	UIHelper.SetVisible(self.scriptTop.ScrollViewTopAnchoreContentList2, false)
    UIHelper.SetVisible(self.scriptTop.ScrollViewTopAnchoreContentList3, true)

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIOperationRewardPreview:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIOperationRewardPreview:BindUIEvent()

end

function UIOperationRewardPreview:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIOperationRewardPreview:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end


-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIOperationRewardPreview:UpdateInfo()
    local tList = Table_GetOperationRewardPreview()
    if not tList or #tList == 0 then
        return
    end

    self.tCellScripts = {}

    local scrollView = self.scriptTop.ScrollViewTopAnchoreContentList3
    UIHelper.RemoveAllChildren(scrollView)

    for nIndex, tInfo in ipairs(tList) do
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetRewardUpdateCell, scrollView)
        if script then
            -- 卡片背景图
            if tInfo.szMobileBgFrame and tInfo.szMobileBgFrame ~= "" then
                UIHelper.SetSpriteFrame(script.ImgQualityBg, tInfo.szMobileBgFrame)
            end

            -- Tag图片
            if tInfo.szMobileTagFrame and tInfo.szMobileTagFrame ~= "" then
                UIHelper.SetSpriteFrame(script.ImgTag, tInfo.szMobileTagFrame)
            end

            -- 类型名字，GBK转UTF8
            local szTag = tInfo.szTag or ""
            if szTag ~= "" then
                UIHelper.SetString(script.LabelType, UIHelper.GBKToUTF8(szTag))
            end

            -- 道具信息
            local tItem = ItemData.GetItemInfo(tInfo.dwTabType, tInfo.dwIndex)
            if tItem then
                -- 道具图标
                local bIsItemIcon = false
                local szIconPath = self:GetIconPath(tInfo)
                if string.is_nil(szIconPath) then
                    local nItemIconID = Table_GetItemIconID(tItem.nUiId)
                    szIconPath = UIHelper.GetIconPathByIconID(nItemIconID)--Table_GetItemLargeIconPathByItemUiId(tItem.nUiId)
                    bIsItemIcon = true
                end

                if szIconPath then
                    UIHelper.SetTexture(script.ImgItem, szIconPath)

                    local nScale = bIsItemIcon and 0.6 or 1
                    UIHelper.SetScale(script.ImgItem, nScale, nScale)
                end

                -- 道具名字，最多显示5个字
                local szItemName = Table_GetItemName(tItem.nUiId)
                if szItemName then
                    UIHelper.SetString(script.LabelItemName, UIHelper.GBKToUTF8(szItemName), 5)
                end
            end

            -- 绑定Toggle选中事件
            local nCurIndex = nIndex
            if script.ToggleSelect then
                UIHelper.BindUIEvent(script.ToggleSelect, EventType.OnSelectChanged, function(_, bSelected)
                    if bSelected then
                        self:OnSelectCell(nCurIndex)
                    end
                end)
            end

            table.insert(self.tCellScripts, {script = script, tInfo = tInfo})
        end
    end

    UIHelper.ScrollViewDoLayoutAndToTop(scrollView)

    -- 默认选中第一个
    if #self.tCellScripts > 0 then
        UIHelper.SetSelected(self.tCellScripts[1].script.ToggleSelect, true)
    end
end

function UIOperationRewardPreview:GetIconPath(tInfo)
    local szIconPath = ""

    if tInfo then
        if tInfo.szMobileImagePath and tInfo.szMobileImagePath ~= "" then
            szIconPath = tInfo.szMobileImagePath
        else
            local tbBodyPaths = {
                [ROLE_TYPE.STANDARD_MALE] = tInfo.szMobileMalePath or "",
                [ROLE_TYPE.STANDARD_FEMALE] = tInfo.szMobileFemalePath or "",
                [ROLE_TYPE.LITTLE_BOY] = tInfo.szMobileBoyPath or "",
                [ROLE_TYPE.LITTLE_GIRL] = tInfo.szMobileGirlPath or "",
            }

            local nRoleType = g_pClientPlayer and g_pClientPlayer.nRoleType
            szIconPath = tbBodyPaths[nRoleType]
        end
    end

    return szIconPath
end

function UIOperationRewardPreview:OnSelectCell(nIndex)
    if not self.tCellScripts or not self.tCellScripts[nIndex] then
        return
    end

    -- 更新所有Toggle状态
    -- for i, tEntry in ipairs(self.tCellScripts) do
    --     if tEntry.script.ToggleSelect then
    --         UIHelper.SetSelected(tEntry.script.ToggleSelect, i == nIndex)
    --     end
    -- end

    -- 更新中间大图
    local tInfo = self.tCellScripts[nIndex].tInfo
    local scriptCenter = self.tComponentContext and self.tComponentContext.scriptCenter
    if scriptCenter then
        -- 视频
        if tInfo.szMobileVideoPath and tInfo.szMobileVideoPath ~= "" then
            scriptCenter:PlayVideo(nil, tInfo.szMobileVideoPath, true)
        else
            scriptCenter:PlayVideo(scriptCenter:GetCurActivityConf())
        end

        -- 按钮
        self:UpdateButton(tInfo.nMobileBtnID)

        -- 左上角道具名字和类型图片
        local szItemName = ""
        local tItem = ItemData.GetItemInfo(tInfo.dwTabType, tInfo.dwIndex)
        if tItem then
            local szName = Table_GetItemName(tItem.nUiId)
            if szName then
                szItemName = UIHelper.GBKToUTF8(szName)
                szItemName = string.gsub(szItemName, "（", "︵")
                szItemName = string.gsub(szItemName, "）", "︶")

                szItemName = string.gsub(szItemName, "【", "︻")
                szItemName = string.gsub(szItemName, "】", "︼")
            end
        end
        local szTypeImg = tInfo.szMobileRewardTypeFrame or ""
        scriptCenter:SetContentNameTitle(szItemName, szTypeImg)

        -- PageView
        local tbListPath = {}
        local nRoleType = g_pClientPlayer and g_pClientPlayer.nRoleType
        local nSelectIdx = 1

        if tInfo.szMobileImagePath and tInfo.szMobileImagePath ~= "" then
            table.insert(tbListPath, tInfo.szMobileImagePath)
        else
            local bSelfBodyOnly = tInfo.bMobileSelfBodyOnly
            local tbBodyPaths = {
                {nRoleType = ROLE_TYPE.STANDARD_MALE,   szPath = tInfo.szMobileMalePath or ""},
                {nRoleType = ROLE_TYPE.STANDARD_FEMALE, szPath = tInfo.szMobileFemalePath or ""},
                {nRoleType = ROLE_TYPE.LITTLE_BOY,      szPath = tInfo.szMobileBoyPath or ""},
                {nRoleType = ROLE_TYPE.LITTLE_GIRL,     szPath = tInfo.szMobileGirlPath or ""},
            }

            for k, tBody in ipairs(tbBodyPaths) do
                if tBody.szPath ~= "" and (not bSelfBodyOnly or (bSelfBodyOnly and tBody.nRoleType == nRoleType)) then
                    table.insert(tbListPath, tBody.szPath)

                    if nRoleType == tBody.nRoleType then
                        nSelectIdx = k
                    end
                end
            end
        end

        scriptCenter:SetMiddlePageView(tbListPath, nSelectIdx)
    end
end

function UIOperationRewardPreview:UpdateButton(nBtnID)
    local scriptCenter = self.tComponentContext and self.tComponentContext.scriptCenter
    if not scriptCenter then
        return
    end

    local tbButton = scriptCenter:GetButton()
    local btn = tbButton and tbButton[1]
    if btn then
        if not nBtnID or nBtnID <= 0 then
            UIHelper.SetVisible(btn, false)
            return
        end

        UIHelper.SetVisible(btn, true)

        local scriptBtn = UIHelper.GetBindScript(btn)
        scriptBtn:OnEnter(nBtnID, nil)
        scriptBtn:UpdateBtnDes("前往获得")
    end
end

return UIOperationRewardPreview
