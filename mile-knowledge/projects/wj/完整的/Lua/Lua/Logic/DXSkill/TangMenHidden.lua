TangMenHidden = TangMenHidden or { className = "TangMenHidden" }
local self = TangMenHidden

TangMenHidden.nSkillIDToFeiXingIcon = {
    [17587] = "UIAtlas2_SkillDX_SpecialSkill_TangMen_FeiXing_yellow.png",
    [17588] = "UIAtlas2_SkillDX_SpecialSkill_TangMen_FeiXing_blue.png"
}

TangMenHidden.tShadowList = {}
function TangMenHidden.DeleteOneHidden(dwSkillID)
    local tList = {}
    local nCount = table.get_len(self.tShadowList)
    if nCount <= 0 then
        return tList
    end

    SpecialDXSkillData.ClearSkillBuffTimeEnd(dwSkillID)

    for i = 1, nCount, 1 do
        local tSkill = self.tShadowList[i]
        if tSkill.id and dwSkillID ~= tSkill.id then
            table.insert(tList, { id = tSkill.id,
                                  level = tSkill.level,
                                  dwNpcID = tSkill.dwNpcID,
                                  buff = tSkill.nBuff or 0,
            })
        end
    end

    self.tShadowList = tList
end

function TangMenHidden.AddOneHidden(dwSkillID, dwNpcID, bNotJudge, dwBuff)
    local tList = self.tShadowList or {}
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    SpecialDXSkillData.ClearSkillBuffTimeEnd(dwSkillID)

    local dwLevel = hPlayer.GetSkillLevel(dwSkillID)
    if dwLevel == 0 then
        dwLevel = 1
    end
    table.insert(tList, { id = dwSkillID, level = dwLevel, dwNpcID = dwNpcID, buff = dwBuff })

    self.tShadowList = tList
end

function TangMenHidden.GetFlyStarList()
    return self.tShadowList
end

Event.Reg(self, "UPDATE_NEW_HIDDEN", function(tShadowList)
    print("TangMenHidden UPDATE_NEW_HIDDEN")
    self.tShadowList = tShadowList
    Event.Dispatch(EventType.OnTangMenHiddenChanged)
end)

Event.Reg(self, "DELETE_ONE_HIDDEN", function()
    print("TangMenHidden DELETE_ONE_HIDDEN")
    self.DeleteOneHidden(arg0)
    Event.Dispatch(EventType.OnTangMenHiddenChanged)
end)

Event.Reg(self, "DELETE_ONE_SHADOW", function()
    print("TangMenHidden DELETE_ONE_SHADOW")
    self.DeleteOneHidden(arg0) 
    Event.Dispatch(EventType.OnTangMenHiddenChanged) -- 端游脚本蜜汁混用了唐门和长歌的事件
end)

Event.Reg(self, "ADD_ONE_HIDDEN", function()
    print("TangMenHidden ADD_ONE_HIDDEN")
    self.AddOneHidden(arg0, arg1, arg2, arg3)
    Event.Dispatch(EventType.OnTangMenHiddenChanged)
end)

Event.Reg(self, "OPEN_TM_HIDDEN", function(tShadowList)
    print(" TangMenHidden OPEN_TM_HIDDEN")
    self.tShadowList = tShadowList
    Event.Dispatch(EventType.OnTangMenHiddenChanged)
end)

Event.Reg(self, "CLOSE_TM_HIDDEN", function()
    print(" TangMenHidden CLOSE_TM_HIDDEN")
    self.tShadowList = {}
    Event.Dispatch(EventType.OnTangMenHiddenChanged)
end)

Event.Reg(self, "CLOSE_CHANGGE_SHADOWBAR", function()
    print(" TangMenHidden CLOSE_CHANGGE_SHADOWBAR")
    self.tShadowList = {}
    Event.Dispatch(EventType.OnTangMenHiddenChanged) -- 端游脚本蜜汁混用了唐门和长歌的事件
end)