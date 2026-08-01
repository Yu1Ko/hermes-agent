-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: PersonalCardData
-- Date: 2024-02-02 10:33:39
-- Desc: ?
-- ---------------------------------------------------------------------------------

PersonalCardData = PersonalCardData or {className = "PersonalCardData"}
local self = PersonalCardData
-------------------------------- 消息定义 --------------------------------
PersonalCardData.Event = {}
PersonalCardData.Event.SelfUpdate = "SELF_SHOW_IMAGE_UPDATE" -- 自己重传图片后更新
PersonalCardData.Event.SelfUpdateFailed = "SELF_SHOW_IMAGE_UPDATE_FAILED"

function PersonalCardData.Init()
    PersonalCardData.tSelfShowDataInfo = nil
    PersonalCardData.tSelfImageData = {}
    PersonalCardData.tOtherData = {}
    PersonalCardData.tDecorationPresetDataUI = {}
    PersonalCardData.tSelfImageDataState = {}
    PersonalCardData.nReportTime = 0
    PersonalCardData.tShowSelfImage = {}

    Event.Reg(self, "UPLOAD_SHOW_IMAGE_RESPOND", function(bSuccess, dwImageIndex)
        if bSuccess == 1 then
            if g_pClientPlayer then
                g_pClientPlayer.SelectShowCardDecorationPreset(dwImageIndex)
                PersonalCardData.SetShowCardPresetState(dwImageIndex, SHOW_CARD_PRESET_STATE_TYPE.UPLOAD_IMAGE, true)
                PersonalCardData.CleanSelfImage(dwImageIndex)
                PersonalCardData.tSelfImageDataState[dwImageIndex] = true
                Event.Dispatch(PersonalCardData.Event.SelfUpdate)
                Timer.Add(self, 5, function()
                    PersonalCardData.DownloadShowCardImage(g_pClientPlayer.GetGlobalID(), dwImageIndex)
                end)
            end
        else
            Event.Dispatch(PersonalCardData.Event.SelfUpdateFailed, dwImageIndex)
        end
    end)

    Event.Reg(self, "SCENE_BEGIN_LOAD", function() -- 切场景时清空数据
        PersonalCardData.CleanSelfImage()
    end)
end

function PersonalCardData.UnInit()

end

function PersonalCardData.ClearData()
    PersonalCardData.tSelfShowDataInfo = nil
    PersonalCardData.CleanSelfImage()
    PersonalCardData.tSelfImageDataState = {}
    PersonalCardData.tShowSelfImage = {}
end

function PersonalCardData.OnLogin()

end

function PersonalCardData.OnFirstLoadEnd()

end

function PersonalCardData.SetShowSelfImage(pdata, nsize)
    PersonalCardData.tShowSelfImage = {}
    PersonalCardData.tShowSelfImage.pdata = pdata
    PersonalCardData.tShowSelfImage.nsize = nsize
end

function PersonalCardData.GetShowSelfImage()
    if PersonalCardData.tShowSelfImage.pdata and PersonalCardData.tShowSelfImage.nsize then
        return PersonalCardData.tShowSelfImage.pdata, PersonalCardData.tShowSelfImage.nsize
    end
end

function PersonalCardData.GetImageIndexAndState(szGlobalID)
    local ShowCardManager = GetShowCardCacheManager()
    if not ShowCardManager then
        return
    end

    return ShowCardManager.GetImageIndexAndState(szGlobalID)
end

function PersonalCardData.ApplyShowCardData(szGlobalID)
    local ShowCardManager = GetShowCardCacheManager()
    if not ShowCardManager then
        return
    end

    ShowCardManager.ApplyShowCardData(szGlobalID)
end

function PersonalCardData.ApplyTableShowCardData(tGlobalID)
    local ShowCardManager = GetShowCardCacheManager()
    if not ShowCardManager then
        return
    end

    local tApplyGlobalID = {}
    for _, szGlobalID in ipairs(tGlobalID) do
        if PersonalCardData.CheckPeekID(szGlobalID) then
            table.insert(tApplyGlobalID, szGlobalID)
        end
    end
    ShowCardManager.ApplyShowCardData(tApplyGlobalID)
end

function PersonalCardData.CheckPeekID(szGlobalID)
    if GDAPI_CanPeekPersonalCard and not GDAPI_CanPeekPersonalCard(szGlobalID) then
        return false
    end
    return true
end

function PersonalCardData.GetDecorationPreset(szGlobalID)
    local ShowCardManager = GetShowCardCacheManager()
    if not ShowCardManager then
        return
    end

    return ShowCardManager.GetDecorationPreset(szGlobalID)
end

function PersonalCardData.GetShowData(szGlobalID)
    local ShowCardManager = GetShowCardCacheManager()
    if not ShowCardManager then
        return
    end

    return ShowCardManager.GetShowData(szGlobalID)
end

function PersonalCardData.DownloadShowCardImage(szGlobalID, dwImageIndex)
    local ShowCardManager = GetShowCardCacheManager()
    if not ShowCardManager then
        return
    end

    return ShowCardManager.DownloadShowCardImage(szGlobalID, dwImageIndex)
end

function PersonalCardData.UploadShowCardImage(dwImageIndex)
    local ShowCardManager = GetShowCardCacheManager()
    if not ShowCardManager then
        return
    end

    return ShowCardManager.UploadShowCardImage(dwImageIndex)
end

function PersonalCardData.LogicLayer2UILayer(tDecorationPresetLogic)
    local tDecorationPresetDataUI = {}

    for _, v in ipairs(tDecorationPresetLogic) do
        if v.nDecorationType == SHOW_CARD_DECORATION_TYPE.FRAME then
            tDecorationPresetDataUI[6] = clone(v)
        else
            tDecorationPresetDataUI[v.byLayer] = clone(v)
        end
    end

    if not tDecorationPresetDataUI[6] then
        tDecorationPresetDataUI[6] = {["wID"] = 0, ["fOffsetX"] = 0, ["fOffsetY"] = 0, ["fScale"] = 1, ["byLayer"] = 6, ["byRotation"] = 0}
    end

    return tDecorationPresetDataUI
end

function PersonalCardData.DXOffsetTranslate2VK(tDecorationPresetDataUI, i, nWidgetWidth, nWidgetHeight)
    local fOffsetX = tDecorationPresetDataUI[i].fOffsetX
    local fOffsetY = tDecorationPresetDataUI[i].fOffsetY

    local fVKOffsetX = fOffsetX * 2 - nWidgetWidth / 2
    local fVKOffsetY = (nWidgetHeight / 2) - fOffsetY * 2

    return fVKOffsetX, fVKOffsetY
end

-- 数据清理
function PersonalCardData.CleanSelfImage(dwID)
    if PersonalCardData.tSelfImageData then
        if dwID then
            if PersonalCardData.tSelfImageData[dwID] and
                PersonalCardData.tSelfImageData[dwID].pRetTexture then
                local picTexture = PersonalCardData.tSelfImageData[dwID].pRetTexture
                picTexture:release()
            end
            PersonalCardData.tSelfImageData[dwID] = nil
        else
            for nIndex = 1, 3 do
                if PersonalCardData.tSelfImageData[nIndex] and
                    PersonalCardData.tSelfImageData[nIndex].pRetTexture then
                    local picTexture = PersonalCardData.tSelfImageData[nIndex].pRetTexture
                    picTexture:release()
                end
            end
            PersonalCardData.tSelfImageData = {}
        end
    end
end

-- 名片数据相关
function PersonalCardData.GetSelfShowCardData(tData)
    local function fnADegree(a, b)
        if a.nGrade == b.nGrade then
            return a.dwKey < b.dwKey
        else
            return a.nGrade > b.nGrade
        end
    end

    local function fnDegree(a, b)
		if a.bShow and b.bShow then
			return fnADegree(a, b)
		elseif a.bShow then
			return true
		elseif b.bShow then
			return false
		else
			return a.dwKey < b.dwKey
		end
	end

    PersonalCardData.tSelfShowDataInfo = tData
    for key, tDataLine in pairs (tData) do
        local tSettingLine = Table_GetPersonalCardData(self.tSelfShowDataInfo[key].dwKey)
        self.tSelfShowDataInfo[key].szName = UIHelper.GBKToUTF8(tSettingLine.szName)
        local nValue = 0
        if tSettingLine.nLevelValue1 > self.tSelfShowDataInfo[key].nValue1 then
            nValue = 0
        elseif tSettingLine.nLevelValue2 > self.tSelfShowDataInfo[key].nValue1 then
            nValue = 1
        elseif tSettingLine.nLevelValue3 > self.tSelfShowDataInfo[key].nValue1 then
            nValue = 2
        elseif tSettingLine.nLevelValue4 > self.tSelfShowDataInfo[key].nValue1 then
            nValue = 3
        elseif tSettingLine.nLevelValue5 > self.tSelfShowDataInfo[key].nValue1 then
            nValue = 4
        else
            nValue = 5
        end
        self.tSelfShowDataInfo[key].nGrade = nValue
        if nValue == 0 then
            self.tSelfShowDataInfo[key].Img = "mui/Resource/PersonalCard/PersonalIcon/unshow.png"
            self.tSelfShowDataInfo[key].bShow = false
        else
            self.tSelfShowDataInfo[key].Img = PersonalCardData.GetImageOfShowCardData(self.tSelfShowDataInfo[key].dwKey, nValue)
            self.tSelfShowDataInfo[key].bShow = true
        end
    end

    table.sort(self.tSelfShowDataInfo, fnDegree)

    return PersonalCardData.tSelfShowDataInfo
end

function PersonalCardData.GetImageOfShowCardData(nKey, nValue)
    local SHOWCARDDATA_Image = {
        [10] = "jhzl", -- 江湖资历
        [11] = "mjdhe", -- 名剑大会2
        [12] = "mjdhs", -- 名剑大会3
        [13] = "mjdhw", -- 名剑大会5
        [14] = "sdrs",  -- 伤敌人数
        [15] = "zjzg", -- 最佳助攻
        [16] = "zjdj", -- 战阶等级
        [17] = "cwfs", -- 宠物分数
        [18] = "sw", --声望
        [19] = "jsqy", -- 绝世奇遇
        [20] = "ptqy", -- 普通奇遇
        [21] = "cwqy", -- 宠物奇遇
        [22] = "cy", -- 成衣
        [23] = "fx", -- 发型
        [24] = "pf", -- 披风
        [25] = "gsmj", -- 挂饰秘鉴
        [26] = "jjscf", -- 家园收藏分
        [27] = "jjcj", -- 绝境吃鸡
        [28] = "slzd", -- 试炼之地
        [29] = "szpf", -- 私宅皮肤
        [30] = "stz", -- 师徒值
        [31] = "mjsl", -- 秘境首领
        [32] = "qdcs", -- 签到次数
        [33] = "jjxk", -- 结交侠客
        [34] = "syz", -- 韶仪值
    }
    local prefix = "mui/Resource/PersonalCard/PersonalIcon/"
    local postfix = SHOWCARDDATA_Image[nKey] .. nValue .. ".png"
    local fileName = prefix .. postfix
    return fileName
end

-- 设置玩家某个名片图片的状态（是否上传过）
function PersonalCardData.SetShowCardPresetState(dwIndex, dwPos, bState)
    if not g_pClientPlayer then return end
    dwPos = dwPos or 0
    g_pClientPlayer.SetShowCardPresetState(dwIndex, dwPos, bState)
    
end

-- 获取玩家某套名片预设的状态
function PersonalCardData.GetShowCardPresetState(dwIndex, dwPos)
    if not g_pClientPlayer then return end
    dwPos = dwPos or 0
    return g_pClientPlayer.GetShowCardPresetState(dwIndex, dwPos)
end

function PersonalCardData.GetAllShowCardDecorationPreset()
    if not g_pClientPlayer then return end
    return g_pClientPlayer.GetAllShowCardDecorationPreset()
end