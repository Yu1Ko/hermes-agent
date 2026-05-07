-- 此处单独起boss对应的buff
-- 逻辑为buff,最后为执行的时间
AutoBuff ={
    -- 太极宫
    ["太极宫"]={
        [1] = nil,
        [2] = nil,
        [3] = {'/gm local scene = player.GetScene();if not scene then return end local npc = scene.GetNpcByNickName("HQ") if not npc then return end npc.FireAIEvent(2016, 0, 0);for i=1,10 do local scene=player.GetScene();if scene.IsNickNameNpcExist("GW_" .. i) then scene.GetNpcByNickName("GW_" .. i).Die() end if scene.IsNickNameNpcExist("DW_" .. i) then scene.GetNpcByNickName("DW_" .. i).Die() end if scene.IsNickNameNpcExist("QW_" .. i) then scene.GetNpcByNickName("QW_" .. i).Die() end if scene.IsNickNameNpcExist("QB_" .. i) then scene.GetNpcByNickName("QB_" .. i).Die() end end;for i=1,1 do player.AddBuff(player.dwID,player.nLevel,29987,1,3600) end',1},
        [4] = nil,
        [5] = {'/gm for i=1,10 do local scene=player.GetScene();if scene.IsNickNameNpcExist("TuXiZhe" .. i) then scene.GetNpcByNickName("TuXiZhe" .. i).Die() end end',20},
        [6] = {'/gm for i=1,100 do local scene=player.GetScene();if scene.IsNickNameNpcExist("XZY_KL_" .. i) then scene.GetNpcByNickName("XZY_KL_" .. i).Die() end end)',8}
    },
    ["空城殿"]={
        [1] = {'/gm for i=1,100 do player.DelBuff(30100,1) end',1},
    },
    ["一之窟"]={
        [1] = nil,
        [2] = {'/gm player.GetScene().GetNpcByNickName("WRS").nCurrentMana=0',1},
        [3] = {'/gm player.DelBuff(28862,1)',1},
        [4] = nil,
        [5] = nil,
        [6] = nil,
    },
    ["空城殿下"]={
        [1] = nil,
    },
    ["獭山岛"]={
        [1] = nil,
        [2] = nil,
        [3] = nil,
    },
    ["会战弓月城"]={
        [1] = nil,
        [2] = nil,
        [3] = nil,
        [4] = nil,
        [5] = nil,
    },
    ["缚罪之渊"]={
        [1] = nil,
        [2] = nil,
    },
    ["阆风悬城"]={
        [1] = {'/gm local scene = player.GetScene();local chengshang=scene.GetNpcByNickName("NPC_BoodCheck");chengshang.SetCustomUnsigned1(1,3)'},
        [2] = nil,
        [3] = nil,
        [4] = nil,
    },
}