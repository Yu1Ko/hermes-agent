BuildHairData = BuildHairData or {}

--create里tParams会为以下赋值
--nRoleType
--nForceID
--bPrice
function BuildHairData.Init(tParams)
    for szKey, Data in pairs(tParams) do
		BuildHairData[szKey] = Data
	end

    BuildHairData.ReloadSelectedHair()
    BuildHairData.GetHairClass()
    BuildHairData.GetHairAllConfig()
end

function BuildHairData.UnInit()
    BuildHairData.tHairConfig = nil
    BuildHairData.tHairClass = nil

    BuildHairData.nHair = nil
    BuildHairData.nBang = nil
    BuildHairData.nPlait = nil

    BuildHairData.nShowType = nil
end

function BuildHairData.GetCoinShopHairClass()
    if not BuildHairData.tCoinShopHairClass then
        BuildHairData.tCoinShopHairClass = {
            {
                szName = UIHelper.UTF8ToGBK("全部"),
            },
            {
                szName = UIHelper.UTF8ToGBK("白发"),
            },
            {
                szName = UIHelper.UTF8ToGBK("金发"),
            },
            {
                szName = UIHelper.UTF8ToGBK("套发"),
            },
        }
    end

    return BuildHairData.tCoinShopHairClass
end

function BuildHairData.GetHairClass()
    if not BuildHairData.tHairClass then
        BuildHairData.tHairClass = {
            {
                szName = UIHelper.UTF8ToGBK("发型"),
            },
            {
                szName = UIHelper.UTF8ToGBK("刘海"),
            },
            {
                szName = UIHelper.UTF8ToGBK("辫子"),
            },
        }
    end

    return BuildHairData.tHairClass
end

function BuildHairData.GetHairAllConfig()
    if not BuildHairData.bPrice then
        if not BuildHairData.tHairConfig then
            local tHair = g_tStrings.tHair

            if BuildHairData.nKungfuID == KUNGFU_ID.SHAO_LIN then
                tHair = g_tStrings.tShaoLinHair
            end

            BuildHairData.tHairConfig = tHair[BuildHairData.nRoleType]
        end

        return BuildHairData.tHairConfig
    else
        local tHairMap = CoinShopData.GetShopHairList()
        local nShowType = BuildHairData.GetShowType()
        return tHairMap[nShowType]
    end
end

function BuildHairData.GetHairConfigWithClassIndex(nClassIndex, nSubClassIndex)
    local nHair, nBang, nPlait = BuildHairData.nHair, BuildHairData.nBang, BuildHairData.nPlait
    if BuildHairData.bPrice then
        BuildHairData.SetShowType(nClassIndex)
        nClassIndex = nSubClassIndex

        local tRepresentID = ExteriorCharacter.m_tRepresentID
        local nHairID = tRepresentID[HAIR_STYLE.HAIR]

        local tShopHair = CoinShopData.GetShopHairList()
        local nShowType = BuildHairData.GetShowType()
        local tHair = tShopHair[nShowType]
        for nHairIndex, tHead in ipairs(tHair) do
            for nBangIndex, tBang in ipairs(tHead) do
                for nPlaitIndex, tOneHair in ipairs(tBang) do
                    local nHairID1 = tOneHair[1]
                    if nHairID1 == nHairID then
                        nHair = nHairIndex
                        nBang = nBangIndex
                        nPlait = nPlaitIndex
                        break
                    end
                end
            end
        end
    end

    local hHairShopClient = GetHairShop()
    if not hHairShopClient then
        return
    end

    local tHairConfig = BuildHairData.GetHairAllConfig()
    local tConfig = {}

    if nClassIndex == 1 then
        for nID, tbInfo in ipairs(tHairConfig) do
            local szName = tbInfo.HeadFormName
            if BuildHairData.bPrice then
                local nRepresentID = tbInfo[1][1][1]
                local tHairIndex = {hHairShopClient.GetHairIndex(nRepresentID)}
                nRepresentID = tHairIndex[1]
                local _, szHairName = CoinShopHair.GetHairUIID("Hair", nRepresentID)
                szName = UIHelper.GBKToUTF8(szHairName)
            end

            table.insert(tConfig, {
                nID = nID,
                nClassIndex = nClassIndex,
                szName = szName,
                bHair = true,
            })
        end
    elseif nClassIndex == 2 then
        local tTempConfig = tHairConfig[nHair] or tHairConfig[1]
        if tTempConfig then
            for i = 1, tTempConfig.BangNum, 1 do
                local szName = tTempConfig.BangName and tTempConfig.BangName[i]
                if BuildHairData.bPrice then
                    local nRepresentID = tTempConfig[i][1][1]
                    local tHairIndex = {hHairShopClient.GetHairIndex(nRepresentID)}
                    nRepresentID = tHairIndex[2]
                    local _, szHairName = CoinShopHair.GetHairUIID("Bang", nRepresentID)
                    szName = UIHelper.GBKToUTF8(szHairName)
                end

                table.insert(tConfig, {
                    nID = i,
                    nClassIndex = nClassIndex,
                    szName = szName,
                    bHair = true,
                })
            end
        end

    elseif nClassIndex == 3 then
        local tTempConfig = tHairConfig[nHair] or tHairConfig[1]
        if tTempConfig then
            for i = 1, tTempConfig.PlaitNum, 1 do
                local szName = tTempConfig.PlaitName and tTempConfig.PlaitName[i]
                if BuildHairData.bPrice then
                    local tBangTempConfig = tTempConfig[nBang] or tTempConfig[1]
                    if tBangTempConfig then
                        local nRepresentID = tBangTempConfig[i][1]
                        local tHairIndex = {hHairShopClient.GetHairIndex(nRepresentID)}
                        nRepresentID = tHairIndex[3]
                        local _, szHairName = CoinShopHair.GetHairUIID("Plait", nRepresentID)
                        szName = UIHelper.GBKToUTF8(szHairName)
                    end
                end

                table.insert(tConfig, {
                    nID = i,
                    nClassIndex = nClassIndex,
                    szName = szName,
                })
            end
        end
    end

    return tConfig
end

function BuildHairData.SetClassIndexValue(nClassIndex, nID)
    if nClassIndex == 1 then
        BuildHairData.nHair = nID
        BuildHairData.nBang = 1
        BuildHairData.nPlait = 1
    elseif nClassIndex == 2 then
        BuildHairData.nBang = nID
        BuildHairData.nPlait = 1
    elseif nClassIndex == 3 then
        BuildHairData.nPlait = nID
    end
end

function BuildHairData.GetClassIndexValue(nClassIndex, nSubClassIndex)
    if BuildHairData.bPrice then
        nClassIndex = nSubClassIndex

        local tRepresentID = ExteriorCharacter.m_tRepresentID
        local nNowHair = tRepresentID[HAIR_STYLE.HAIR]

        local tHairConfig = BuildHairData.GetHairAllConfig()
        for nID, tbInfo in ipairs(tHairConfig) do
            for i = 1, tbInfo.BangNum + 1, 1 do
                for j = 1, tbInfo.PlaitNum + 1, 1 do
                    if tbInfo[i] and tbInfo[i][j] and tbInfo[i][j][1] then
                        local nRepresentID = tbInfo[i][j][1]
                        if nNowHair == nRepresentID then
                            if nClassIndex == 1 then
                                return nID
                            elseif nClassIndex == 2 then
                                return i
                            elseif nClassIndex == 3 then
                                return j
                            end
                        end
                    end
                end
            end
        end

        return -1
    end

    if nClassIndex == 1 then
        return BuildHairData.nHair
    elseif nClassIndex == 2 then
        return BuildHairData.nBang
    elseif nClassIndex == 3 then
        return BuildHairData.nPlait
    end
end

function BuildHairData.SetShowType(nShowType)
    BuildHairData.nShowType = nShowType
end

function BuildHairData.GetShowType()
    BuildHairData.nShowType = BuildHairData.nShowType or HAIR_SHOW_TYPE.ALL
    return BuildHairData.nShowType
end

function BuildHairData.GetSelectedHairStyle()
    local tHairConfig = BuildHairData.GetHairAllConfig()

    if not BuildHairData.bPrice then
        if not tHairConfig or
            not tHairConfig[BuildHairData.nHair] then
            return
        end

        return tHairConfig[BuildHairData.nHair].HeadForm
    else
        if not tHairConfig or
            not tHairConfig[BuildHairData.nHair] or
            not tHairConfig[BuildHairData.nHair][BuildHairData.nBang] or
            not tHairConfig[BuildHairData.nHair][BuildHairData.nBang][BuildHairData.nPlait] or
            not tHairConfig[BuildHairData.nHair][BuildHairData.nBang][BuildHairData.nPlait][1] then

            local tRepresentID = ExteriorCharacter.m_tRepresentID
            local nNowHair = tRepresentID[HAIR_STYLE.HAIR]

            return nNowHair
        end

        return tHairConfig[BuildHairData.nHair][BuildHairData.nBang][BuildHairData.nPlait][1]
    end
end

function BuildHairData.GetHairStyleByClassIndexValue(nClassIndex, nID)
    local nHair, nBang, nPlait = BuildHairData.nHair, BuildHairData.nBang, BuildHairData.nPlait
    if nClassIndex == 1 then
        nHair = nID
        nBang = 1
        nPlait = 1
    elseif nClassIndex == 2 then
        nBang = nID
        nPlait = 1
    elseif nClassIndex == 3 then
        nPlait = nID
    end

    local tHairConfig = BuildHairData.GetHairAllConfig()

    if not BuildHairData.bPrice then
        if not tHairConfig or
            not tHairConfig[nHair] or
            not tHairConfig[nHair][nBang] or
            not tHairConfig[nHair][nBang][nPlait] then
            return
        end

        return tHairConfig[nHair][nBang][nPlait]
    else
        if not tHairConfig or
            not tHairConfig[nHair] or
            not tHairConfig[nHair][nBang] or
            not tHairConfig[nHair][nBang][nPlait] or
            not tHairConfig[nHair][nBang][nPlait][1] then

            local tRepresentID = ExteriorCharacter.m_tRepresentID
            local nNowHair = tRepresentID[HAIR_STYLE.HAIR]

            return nNowHair
        end

        return tHairConfig[nHair][nBang][nPlait][1]
    end
end

function BuildHairData.ReloadSelectedHair()
    BuildHairData.nHair = 1
    BuildHairData.nBang = 1
    BuildHairData.nPlait = 1

    if BuildHairData.bPrice then
        local tRepresentID = ExteriorCharacter.m_tRepresentID
        local nHairID = tRepresentID[HAIR_STYLE.HAIR]

        local tShopHair = CoinShopData.GetShopHairList()
        local nShowType = BuildHairData.GetShowType()
        local tHair = tShopHair[nShowType]
        local bFind = false
        for nHairIndex, tHead in ipairs(tHair) do
            if bFind then break end
            for nBangIndex, tBang in ipairs(tHead) do
                if bFind then break end
                for nPlaitIndex, tOneHair in ipairs(tBang) do
                    local nHair = tOneHair[1]
                    if nHair == nHairID then
                        BuildHairData.nHair = nHairIndex
                        BuildHairData.nBang = nBangIndex
                        BuildHairData.nPlait = nPlaitIndex
                        bFind = true
                        break
                    end
                end
            end
        end

        if not bFind then
            BuildHairData.nHair = -1
            BuildHairData.nBang = -1
            BuildHairData.nPlait = -1
        end
    end
end

function BuildHairData.ResetHair()
    if BuildHairData.bPrice then
        local tRepresentID = g_pClientPlayer.GetRepresentID()
        local nHairID = tRepresentID[HAIR_STYLE.HAIR]
        ExteriorCharacter.PreviewHair(nHairID, nil, true)
    end

    BuildHairData.ReloadSelectedHair()
end