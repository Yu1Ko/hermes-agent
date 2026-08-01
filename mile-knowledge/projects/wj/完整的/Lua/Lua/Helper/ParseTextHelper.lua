-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: ParseTextHelper
-- Date: 2022-12-21 10:55:39
-- Desc: ?
-- ---------------------------------------------------------------------------------

ParseTextHelper = ParseTextHelper or {}
local self = ParseTextHelper
-------------------------------- 消息定义 --------------------------------
ParseTextHelper.Event = {}
ParseTextHelper.Event.XXX = "ParseTextHelper.Msg.XXX"

function ParseTextHelper.Init()

end

function ParseTextHelper.UnInit()

end

function ParseTextHelper.OnLogin()

end

function ParseTextHelper.OnFirstLoadEnd()

end

----原始格式:
--<text>text="..."font=...</text><text>text="..."font=...</text><text>text="..."font=...</text>

local function ConvertText(szTarget, szSeparator)
    local tItemInfo
    local szContent = string.match(szTarget, "text=\"(.-)\"")
    local szFontID = string.match(szTarget, "font=(%d+)")
    local szUrl = string.match(szTarget, "link=\"(.-)\"")
    local szTypeName = string.match(szTarget, "name=\"(.-)\"")
    local szItemTabType = string.match(szTarget, "dwTabType=(%d+)")
    local szItemTabIndex = string.match(szTarget, "dwIndex=(%d+)")
    local tbColor = UIDialogueColorTab[tonumber(szFontID)]

    -- 文本中包含的>、<等符号，RichText要转义，其它的没用到不知道要不要转，这里先对text的转了
    szContent = UIHelper.RichTextEscape(szContent)

    if not string.is_nil(szItemTabType) and not string.is_nil(szItemTabIndex) then
        local dwItemTabType = tonumber(szItemTabType)
        local dwItemTabIndex = tonumber(szItemTabIndex)
        tItemInfo = ItemData.GetItemInfo(tonumber(dwItemTabType), dwItemTabIndex)
    end

    if szTypeName == "iteminfolink" and tItemInfo then
        local szQuility =  ItemQualityColor[tItemInfo.nQuality + 1] or nil
        if szQuility then
            szContent = string.format("<color=%s>", szQuility) ..szContent.."</color>"
        end
    elseif tbColor then
        local szColor = tbColor.Color
        if string.sub(szColor, 1, 1) ~= "#" then
            szColor = "#" .. szColor
        end
        szContent = string.format("<color=%s>", szColor)..szContent.."</color>"
    else
        szContent = "<color=#E2F6FB>"..szContent.."</color>"
    end

    if szUrl then
        szUrl = string.gsub(szUrl, "/", szSeparator)--链接不能包含/字符
        szContent = string.format("<href=%s>", szUrl) ..szContent.."</href>"
    elseif szTypeName == "iteminfolink" and tItemInfo then
        local tbLinkData = {type = "iteminfolink", nTabtype = tonumber(szItemTabType), nIndex = tonumber(szItemTabIndex)}
        local szLink = JsonEncode(tbLinkData)
        szLink = UrlEncode(szLink)
        szContent = string.format("<href=%s>", szLink) ..szContent.."</href>"
    end
    return szContent
end

function ParseTextHelper.ParseNormalText(szText, bLabel, szSeparator, bKeepEveryText)
    bLabel = bLabel == nil and true or bLabel
    szSeparator = szSeparator or ""
    if bKeepEveryText == nil then
        bKeepEveryText = false
    end

    local szRes = ""
    if szText and string.find(szText, "text=") then
        if bLabel then
            szRes = string.pure_text(szText)
        elseif bKeepEveryText then
            szText = string.gsub(szText, "\\\n", "\n")   -- 策划要求兼容配置表中字符串"\\n"填成"\\\n"的情况
            szRes = string.gsub(szText, "text=.-</text>", function(szSub)
                return ConvertText(szSub, szSeparator)
            end)
        else
            szText = string.gsub(szText, "\\\n", "\n")   -- 策划要求兼容配置表中字符串"\\n"填成"\\\n"的情况
            for szTarget in string.gmatch(szText, "text=.-</text>") do
                szRes = szRes .. ConvertText(szTarget, szSeparator)
            end
        end
    else
        szRes = szText
    end
    if not string.is_nil(szRes) then
        szRes = string.gsub(szRes, '^[%s]*([^%s].*[^%s])[%s]*$', "%1")--清除多余空格
        szRes = string.gsub(szRes, "\\n", "\n")--将\n替换为换行符
        szRes = self.DeleteOperationDesc(szRes)
    end
    return szRes
end

----原始格式:
--<G><F174 ...>\n<H28><G>...\n<H28><G><N>...<F173 ..><N>...
function ParseTextHelper.ParseQuestDesc(szDesc)


    local function GetEncodeName(tInfo)
        local szName = ""
        local nID = tonumber(tInfo.context)
        if nID then
            szName = Table_GetNpcCallMe(nID)
        else
            szName = GetClientPlayer().szName
        end
        return szName
    end

    local _, aInfo = GWTextEncoder_Encode(szDesc)
	if not aInfo then
		return ""
	end

	local szText = ""
	for  k, v in pairs(aInfo) do
		if v.name == "text" then --普通文本
			szText = szText.."<color=#AED9E0>"..UIHelper.GBKToUTF8(v.context).."</color>"
        elseif v.name == "N" then -- NPC对玩家的自定义称呼
            szText = szText..UIHelper.GBKToUTF8(GetEncodeName(v))
		elseif v.name == "C" then	--自己的体型对应的称呼
			szText = szText.."<color=#AED9E0>"..g_tStrings.tRoleTypeToName[g_pClientPlayer.nRoleType].."</color>"
		elseif v.name == "F" then	--字体
            local tbColor = UIDialogueColorTab[tonumber(v.attribute.fontid)]
            if tbColor then
			    szText = szText..string.format("<color=%s>", tbColor.Color)..UIHelper.GBKToUTF8(v.attribute.text).."</color>"
            else
                szText = szText..UIHelper.GBKToUTF8(v.attribute.text)
            end
		elseif v.name == "G" then	--4个英文空格
			local szSpace = g_tStrings.STR_TWO_CHINESE_SPACE
			if v.attribute.english then
				szSpace = "    "
			end
			szText = szText..szSpace
		elseif v.name == "J" then	--金钱
			local nM = tonumber(v.attribute.money)
			szText = szText..UIHelper.GetMoneyText(nM)
		end
	end
    szText = string.gsub(szText, "\\n", "\n")--将\n替换为换行符
    szText = self.DeleteOperationDesc(szText)

    return szText
end

----原始格式:
--<G>...
function ParseTextHelper.ParseQuestObjective(szObjective)
    if string.starts(szObjective, "<G>") then
        local szTarget = string.sub(szObjective, 4, -1)
        return szTarget
    end

    return szObjective
end

--调整对话老面版格式
function ParseTextHelper.ParseOldDialogueText(szText)
    szText = string.gsub(szText, "^[%s\n]+", "")--去掉开头多余空格
    szText = string.gsub(szText, "[%s\n]+$", "")--去掉末尾多余空格
    szText = string.gsub(szText, "<", "【")
    szText = string.gsub(szText, ">", "】")
    return szText
end

--去掉按某键，因为手游操作方式不一样
function ParseTextHelper.DeleteOperationDesc(szText)
    -- szText = string.gsub(szText, "按.+键", "")
    -- szText = string.gsub(szText, "鼠标右键", "")
    -- szText = string.gsub(szText, "鼠标左键", "")
    -- szText = string.gsub(szText, "右键", "")
    -- szText = string.gsub(szText, "左键", "")
    return szText
end

function ParseTextHelper.ParseFontDesc(szDesc)
    local szRes = ParseTextHelper.ParseNormalText(szDesc)
    for szTarget in string.gmatch(szDesc, "text=.-</text>") do
        local szContent = ""
        local szText = string.match(szTarget, "text=\"(.-)\"")
        szText = string.gsub(szText, "\\\n", "\n")
        local nFontID = tonumber(string.match(szTarget, "font=(%d+)"))
        szText = string.gsub(szText, "[%s\n]+$", "")--去掉末尾多余空格
        szText = string.gsub(szText, "[%[%]]", "%%%0")
        if nFontID == 100 then
            szContent = UIHelper.AttachTextColor(szText, "#FFE26E")   --<color> szContent </color>
            szRes = string.gsub(szRes, szText, szContent)
        end
    end
    return szRes
end

--原始格式：
--<image>path="fromiconid" frame=... w=... h=... </image><Text>text="..." font=100 </text>
function ParseTextHelper.ParseFrameDesc(szDesc, nImageSize)
    local szRes = ParseTextHelper.ParseFontDesc(szDesc)
    for szTarget in string.gmatch(szDesc, "<image>.-</text>") do
        local szContent = ""
        local szText = string.match(szTarget, "text=\"(.-)\"")
        szText = string.gsub(szText, "[%[%]]", "%%%0")
        local szFrame = string.match(szTarget, "frame=(%d+)")
        szText = string.gsub(szText, "[%s\n]+$", "")--去掉末尾多余空格
        if szFrame then
            local szItemIconPath = UIHelper.GetIconPathByIconID(tonumber(szFrame), true)
            szFrame = string.format("<img src='%s' width='%d' height='%d' type='0'/>", szItemIconPath, nImageSize*2, nImageSize*2)
            szContent = " "..szText
            szContent = szFrame..szContent  --<img src> szContent
            szRes = string.gsub(szRes, szText, szContent)
        end
    end
    return szRes
end

--- 将端游的富文本改写为bd版支持的富文本，尤其是将其中的link字段改写为bd版的href字段，方便实现点击跳转等功能
---
--- 输入格式
--- <text>text="在" font=162</text><text>text="韩荞生" font=67 link="NPCGuide/132"</text>
--- 输出格式
--- 在<href="NPCGuide/132">韩荞生</href>
function ParseTextHelper.ConvertRichTextFormat(szText, bConvertColor)
    szText                     = string.gsub(szText, "\\\n", "\n")  -- 策划要求兼容配置表中字符串"\\n"填成"\\\n"的情况

    -- 定义匹配模式
    local szTextPattern        = "<text>(.-)</text>"
    local szLinkPattern        = "link=\"(.-)\""
    local szTextContentPattern = "text=\"(.-)\""
    local szFontContentPattern = "font=(%d+)"

    -- 提取富文本 text 标签内的所有内容
    local tTextParts           = {}
    for part in string.gmatch(szText, szTextPattern) do
        table.insert(tTextParts, part)
    end

    -- 转换为bd版本的富文本格式
    local tBDRichTextList = {}
    for _, szPart in ipairs(tTextParts) do
        local szLink      = string.match(szPart, szLinkPattern)
        local szTextValue = string.match(szPart, szTextContentPattern)
        local szFontID = string.match(szPart, szFontContentPattern)

        if szLink then
            -- 如果包含链接，则转写为bd版支持的链接格式
            szLink               = Base64_Encode(szLink)
            local szTextWithLink = string.format("<href=%s><color=#F9B222>%s</color></href>", szLink, szTextValue)
            table.insert(tBDRichTextList, szTextWithLink)
        else
            if bConvertColor then
                local tbColor = UIDialogueColorTab[tonumber(szFontID)]
                if szFontID and tbColor then
                    szTextValue = string.format("<color=%s>", tbColor.Color)..szTextValue.."</color>"
                else
                    szTextValue = "<color=#E2F6FB>"..szTextValue.."</color>"
                end
            end
            -- 如果不包含link=，则直接提取文本内容
            table.insert(tBDRichTextList, szTextValue)
        end
    end

    -- 拼接最终的结果
    local szRichText = table.concat(tBDRichTextList)

    return szRichText
end

--Html文本转义
function ParseTextHelper.HtmlTextUnescape(szText)
    for szUnescape, szEscape in pairs(HtmlEscapeConfig) do
        szText = string.gsub(szText, szEscape, szUnescape)
    end

    for escape in string.gmatch(szText, "(&.-;)") do
        LOG.ERROR("Unkonwn Escape: %s", tostring(escape))
    end

    return szText
end

--Html文本反转义
function ParseTextHelper.HtmlTextEscape(szText)
    --&一定要在第一个转义，否则会把转义后的文本破坏掉
    szText = string.gsub(szText, "&", "&amp;")
    for szUnescape, szEscape in pairs(HtmlEscapeConfig) do
        if szUnescape ~= "&" then
            szText = string.gsub(szText, szUnescape, szEscape)
        end
    end

    return szText
end


-- 头像路径转换
-- ui\Image\PlayerAvatar\MP_MJ_F2_007.tga
-- \ui\Image\PlayerAvatar\BD_1_DK_1.UITEX
-- ui\Image\PlayerAvatar\JH_1_DK_3-1.UITex
function ParseTextHelper.ConvertAvatarPathText(szImage)
    local szPlistName = string.match(szImage, "\\([^\\]+)UITex")
    if not szPlistName then
        szPlistName = string.match(szImage, "/([^/]+)UITex")
    end
    if not szPlistName then
        szPlistName = string.match(szImage, "\\([^\\]+)UITEX")
    end
    if not szPlistName then
        szPlistName = string.match(szImage, "/([^/]+)UITEX")
    end
    if szPlistName then
        return "Resource/PlayerAvatar/"..szPlistName.."json"
    end

    local szImgName = string.match(szImage, "\\([^\\]+)tga")
    if not szImgName then
        szImgName = string.match(szImage, "/([^/]+)tga")
    end
    if szImage then
        return "Resource/PlayerAvatar/"..szImgName.."png"
    end

end

--将数字转换为xx.xx万
function ParseTextHelper.FormatNumberToTenK(nNumber, nDecimalPlaces, bShowUnit)
	local szUnit = g_tStrings.DIGTABLE.tCharDiH[2]
    if not nNumber or nNumber == 0 then
        return 0 .. (bShowUnit and szUnit or "")
    end

    nDecimalPlaces = nDecimalPlaces or 2

    if nNumber < 10000 then
        return nNumber
    else
        local nWan = nNumber / 10000
        local nMultiplier = 10 ^ nDecimalPlaces
        local nTruncated = math.floor(nWan * nMultiplier) / nMultiplier
        return UIHelper.UTF8ToGBK(nTruncated .. (bShowUnit and szUnit or ""))
    end
end

-- 对一段文字进行分段格式化
-- 如果要添加新的格式，比如[XX]格式:
-- FormatConfig["Bracket"] = {
--     StartPattern = "[", 起始标志
--     EndPattern = "]",   终止标志
--     ExtractContent = function(szText, startPos)
--         -- 提取[XX]内容的逻辑
--     end,
--     FormatContent = function(content)
--         -- 格式化[XX]内容的逻辑
--     end
-- }

-- 格式处理配置表
local FormatConfig = {
    -- <Font XX> 格式处理
    ["MonsterValue"] = {
        StartPattern = "<Mons",
        EndPattern = ">",
        ExtractContent = function(szText, startPos)
            local j = startPos + 5  -- 跳过"<Font"
            -- 跳过空格
            while j <= #szText and szText:sub(j, j) == ' ' do
                j = j + 1
            end
            -- 查找结束标签
            local k = j
            while k <= #szText and szText:sub(k, k) ~= '>' do
                k = k + 1
            end
            if k <= #szText then
                return szText:sub(j, k-1), k + 1
            end
            return nil, startPos + 1
        end,
        FormatContent = function(content)
            return string.format("<color=#E2F6FB>%s</color>", content)
        end
    },

    -- -- {XX} 格式处理
    -- ["SkillNoun"] = {
    --     StartPattern = "{",
    --     EndPattern = "}",
    --     ExtractContent = function(szText, startPos)
    --         local j = startPos + 1  -- 跳过"{"
    --         -- 查找结束大括号
    --         while j <= #szText and szText:sub(j, j) ~= '}' do
    --             j = j + 1
    --         end
    --         if j <= #szText then
    --             return szText:sub(startPos+1, j-1), j + 1
    --         end
    --         return nil, startPos + 1
    --     end,
    --     FormatContent = function(content)
    --         local nIndex = tonumber(content)
    --         if nIndex then
    --             return GetFormatSkillNounText(content)
    --         else
    --             MobileSkill.AppendNoun(content)
    --             return MobileSkill.GetFormatSkillNounText(content)
    --         end
    --     end
    -- },
}

-- 将字符串中的特殊格式替换为相应格式，其他文本按szFormat并返回格式化文本
function ParseTextHelper.DevideFormatText(szText, szFormat)
    if not szText then
        return ""
    end

    local tFields = {}
    local i = 1
    local nLen = #szText

    while i <= nLen do
        local matched = false

        -- 检查所有格式处理器
        for handlerName, handler in pairs(FormatConfig) do
            if szText:sub(i, i + #handler.StartPattern - 1) == handler.StartPattern then
                local content, newPos = handler.ExtractContent(szText, i)
                if content then
                    table.insert(tFields, {
                        type = handlerName,
                        content = content
                    })
                    i = newPos
                    matched = true
                    break
                end
            end
        end

        -- 如果没有匹配到任何格式，提取普通文本
        if not matched then
            local j = i
            -- 查找下一个特殊格式的开始位置
            while j <= nLen do
                local foundSpecial = false
                for handlerName, handler in pairs(FormatConfig) do
                    if szText:sub(j, j + #handler.StartPattern - 1) == handler.StartPattern then
                        foundSpecial = true
                        break
                    end
                end
                if foundSpecial then break end
                j = j + 1
            end

            local szContent = szText:sub(i, j - 1)
            if #szContent > 0 then
                table.insert(tFields, {
                    type = "Text",
                    content = szContent
                })
            end
            i = j
        end
    end

    local tResult = {}
    for _, field in ipairs(tFields) do
        if field.type == "Text" then
            table.insert(tResult, string.format(szFormat, field.content))
        else
            local handler = FormatConfig[field.type]
            if handler then
                table.insert(tResult, handler.FormatContent(field.content))
            end
        end
    end

    return table.concat(tResult)
end