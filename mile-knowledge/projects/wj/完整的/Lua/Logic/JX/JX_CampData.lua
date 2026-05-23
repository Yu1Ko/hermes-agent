JX_CampData = {}

local tZoneBossRelation = {
	------------南平昆仑---------------
	[22] = {
		[6219] = {--方超,当boss摆在map地图，并且在zone范围内，他的生死才会影响战区的状态,bossType=0无名，1复活点，2阵营boss
			zone = 1, bossType = 0, eventInfo =  {[0] = {born = 1, dead = 2}},--活动ID = born切换的战区状态，dead切换的战区状态
		},
		[6220] = {--赵新宇
			zone = 2, bossType = 0, eventInfo = {[0] = {born = 1, dead = 2}},
		},
	},
	[30] = {
		[6221] = {--孙永恒
			zone = 1, bossType = 0, eventInfo = {[0] = {born = 1, dead = 2}},
		},
		[6222] = {--霸图
			zone = 2, bossType = 0, eventInfo = {[0] = {born = 1, dead = 2}},
		},
	},
	------------浩气盟---------------
	[25] = {
		--浩气盟烟雨居舍
		[6230] = {--谢烟客
			zone = 2, bossType = 1, eventInfo = {[706] = {born = 1, dead = 2}, [707] = {born = 4, dead = 3}, },
		},
		[17237] = {--顾延恶
			zone = 2, bossType = 1, eventInfo = {[706] = {born = 2, dead = 1}, [707] = {born = 3, dead = 4}, },
		},

		--浩气盟-栖霞幻境
		[8952] = {--郑鸥
			zone = 3, bossType = 1, eventInfo = {[706] = {born = 1, dead = 2}, [707] = {born = 4, dead = 3}, },
		},
		[17240] = {--陶国栋
			zone = 3, bossType = 1, eventInfo = {[706] = {born = 2, dead = 1}, [707] = {born = 3, dead = 4}, },
		},

		--浩气盟-七星岩
		[8954] = {--陶杰
			zone = 4, bossType = 1, eventInfo = {[706] = {born = 1, dead = 2}, [707] = {born = 4, dead = 3}, },
		},
		[17238] = {--吕沛杰
			zone = 4, bossType = 1, eventInfo = {[706] = {born = 2, dead = 1}, [707] = {born = 3, dead = 4}, },
		},

		--浩气盟-龙隐山
		[8953] = {--周峰
			zone = 5, bossType = 1, eventInfo = {[706] = {born = 1, dead = 2}, [707] = {born = 4, dead = 3}, },
		},
		[17239] = {--张一洋
			zone = 5, bossType = 1, eventInfo = {[706] = {born = 2, dead = 1}, [707] = {born = 3, dead = 4}, },
		},

		--浩气盟-博望坡
		[7766] = {--司空仲平
			zone = 6, count = 2, bossType = 2, eventInfo = {[706] = {born = nil, dead = 2}}
		},
		[16902] = {--肖药儿
			zone = 6, bossType = 2, eventInfo = {[706] = {born = nil, dead = 1}},
		},
		[105770] = {--毕罗巴
			zone = 6, bossType = 2, eventInfo = {[707] = {born = nil, dead = 4}},
		},
		[105790] = {--郭珠
			zone = 6, bossType = 2, eventInfo = {[707] = {born = nil, dead = 3}},
		},

		--浩气盟-兰亭书院
		[105585] = {--原可人,2021.10换小七
			zone = 7, count = 2, bossType = 2, eventInfo = {[706] = {born = nil, dead = 2}},
		},
		[16900] = {--米丽古丽
			zone = 7, bossType = 2, eventInfo = {[706] = {born = nil, dead = 1}},
		},
		[105701] = {--丁丁
			zone = 7, bossType = 2, eventInfo = {[707] = {born = nil, dead = 4}},
		},
		[105627] = {--赵紫儿
			zone = 7, bossType = 2, eventInfo = {[707] = {born = nil, dead = 3}},
		},

		--浩气盟-七星阵
		[7770] = {--月弄痕
			zone = 8, count = 2, bossType = 2, eventInfo = {[706] = {born = nil, dead = 2}},
		},
		[105789] = {--原烟，2021.10换司徒一一
			zone = 8, bossType = 2, eventInfo = {[706] = {born = nil, dead = 1}},
		},
		[105828] = {--司徒一一的机甲，单独加的
			zone = 6, count = 2, bossType = 2, eventInfo = {[707] = {born = nil, dead = 2}},
		},
		[105800] = {--独孤修
			zone = 8, bossType = 2, eventInfo = {[707] = {born = nil, dead = 4}},
		},
		[7775] = {--影
			zone = 8, bossType = 2, eventInfo = {[707] = {born = nil, dead = 3}},
		},

		--浩气盟-璃水河岸
		[7767] = {--张桎辕
			zone = 9, count = 2, bossType = 2, eventInfo = {[706] = {born = nil, dead = 2}},
		},
		[16899] = {--陶寒亭
			zone = 9, bossType = 2, eventInfo = {[706] = {born = nil, dead = 1}},
		},
		[105801] = {--岳琅
			zone = 9, bossType = 2, eventInfo = {[707] = {born = nil, dead = 4}},
		},
		[105802] = {--叶镜池
			zone = 9, bossType = 2, eventInfo = {[707] = {born = nil, dead = 3}},
		},

		--浩气盟-落雁城半山腰
		[106924] = {--原影，2021.10换游驹
			zone = 10, count = 2, bossType = 2, eventInfo = {[706] = {born = nil, dead = 2}},
		},
		[105586] = {--原莫雨，2021.10换白某
			zone = 10, bossType = 2, eventInfo = {[706] = {born = nil, dead = 1}},
		},
		[16903] = {--烟
			zone = 10, bossType = 2, eventInfo = {[707] = {born = nil, dead = 4}},
		},
		[105700] = {--莫玄英
			zone = 10, bossType = 2, eventInfo = {[707] = {born = nil, dead = 3}},
		},

		--浩气盟-落雁城老谢处
		[7776] = {--谢渊
			zone = 11, count = 10, bossType = 2, eventInfo = {[706] = {born = nil, dead = 2}},
		},
		[16905] = {--王遗风
			zone = 11, bossType = 2, eventInfo = {[706] = {born = nil, dead = 1}},
		},
		[105673] = {--伊夜
			zone = 11, bossType = 2, eventInfo = {[707] = {born = nil, dead = 4}},
		},
		[105791] = {--韩非池
			zone = 11, bossType = 2, eventInfo = {[707] = {born = nil, dead = 3}},
		},
	},
	------------恶人谷---------------
	[27] = {
		--恶人谷-平安客栈
		[6233] = {--顾延恶
			zone = 2, bossType = 1, eventInfo = {[707] = {born = 1, dead = 2}, [706] = {born = 4, dead = 3}, },
		},
		[17233] = {--谢烟客
			zone = 2, bossType = 1, eventInfo = {[707] = {born = 2, dead = 1}, [706] = {born = 3, dead = 4}, },
		},

		--恶人谷-白骨陵园
		[8955] = {--陶国栋
			zone = 3, bossType = 1, eventInfo = {[707] = {born = 1, dead = 2}, [706] = {born = 4, dead = 3}, },
		},
		[17236] = {--郑鸥
			zone = 3, bossType = 1, eventInfo = {[707] = {born = 2, dead = 1}, [706] = {born = 3, dead = 4}, },
		},

		--恶人谷-炎狱山
		[8956] = {--吕沛杰
			zone = 4, bossType = 1, eventInfo = {[707] = {born = 1, dead = 2}, [706] = {born = 4, dead = 3}, },
		},
		[17234] = {--陶杰
			zone = 4, bossType = 1, eventInfo = {[707] = {born = 2, dead = 1}, [706] = {born = 3, dead = 4}, },
		},

		--恶人谷-炎狱山
		[8957] = {--张一洋
			zone = 5, bossType = 1, eventInfo = {[707] = {born = 1, dead = 2}, [706] = {born = 4, dead = 3}, },
		},
		[17235] = {--周峰
			zone = 5, bossType = 1, eventInfo = {[707] = {born = 2, dead = 1}, [706] = {born = 3, dead = 4}, },
		},

		--恶人谷-尚兽院
		[105789] = {--原烟，2021.10改为司徒一一
			zone = 6, count = 2, bossType = 2, eventInfo = {[707] = {born = nil, dead = 2}},
		},
		[105828] = {--司徒一一的机甲，单独加的
			zone = 6, count = 2, bossType = 2, eventInfo = {[707] = {born = nil, dead = 2}},
		},
		[16896] = {--月弄痕
			zone = 6, bossType = 2, eventInfo = {[707] = {born = nil, dead = 1}},
		},
		[16897] = {--影
			zone = 6, bossType = 2, eventInfo = {[706] = {born = nil, dead = 4}},
		},
		[105800] = {--独孤修
			zone = 6, bossType = 2, eventInfo = {[706] = {born = nil, dead = 3}},
		},

		--恶人谷-毒皇院
		[7783] = {--肖药儿
			zone = 7, count = 2, bossType = 2, eventInfo = {[707] = {born = nil, dead = 2}},
		},
		[16893] = {--司空仲平
			zone = 7, bossType = 2, eventInfo = {[707] = {born = nil, dead = 1}},
		},
		[105790] = {--郭珠
			zone = 7, bossType = 2, eventInfo = {[706] = {born = nil, dead = 4}},
		},
		[105770] = {--毕罗巴
			zone = 7, bossType = 2, eventInfo = {[706] = {born = nil, dead = 3}},
		},

		--恶人谷-酒池峡
		[7779] = {--米丽古丽
			zone = 8, count = 2, bossType = 2, eventInfo = {[707] = {born = nil, dead = 2}},
		},
		[105585] = {--原可人，2021.10修改为小七
			zone = 8, bossType = 2, eventInfo = {[707] = {born = nil, dead = 1}},
		},
		[105627] = {--赵紫儿
			zone = 8, bossType = 2, eventInfo = {[706] = {born = nil, dead = 4}},
		},
		[105701] = {--丁丁
			zone = 8, bossType = 2, eventInfo = {[706] = {born = nil, dead = 3}},
		},

		--恶人谷-小少林
		[105586] = {--原莫雨，2021.10修改为白某
			zone = 9, count = 2, bossType = 2, eventInfo = {[707] = {born = nil, dead = 2}},
		},
		[106924] = {--原影，2021.10修改为游驹
			zone = 9, bossType = 2, eventInfo = {[707] = {born = nil, dead = 1}},
		},
		[105700] = {--穆玄英
			zone = 9, bossType = 2, eventInfo = {[706] = {born = nil, dead = 4}},
		},
		[7784] = {--烟
			zone = 9, bossType = 2, eventInfo = {[706] = {born = nil, dead = 3}},
		},

		--恶人谷-烈风集入口
		[7777] = {--陶寒亭
			zone = 10, count = 2, bossType = 2, eventInfo = {[707] = {born = nil, dead = 2}},
		},
		[16894] = {--张桎辕
			zone = 10, bossType = 2, eventInfo = {[707] = {born = nil, dead = 1}},
		},
		[105802] = {--叶镜池
			zone = 10, bossType = 2, eventInfo = {[706] = {born = nil, dead = 4}},
		},
		[105801] = {--岳琅
			zone = 10, bossType = 2, eventInfo = {[706] = {born = nil, dead = 3}},
		},

		--恶人谷-烈风集高处
		[7786] = {--王遗风
			zone = 11, count = 10, bossType = 2, eventInfo = {[707] = {born = nil, dead = 2}},
		},
		[16898] = {--谢渊
			zone = 11, bossType = 2, eventInfo = {[707] = {born = nil, dead = 1}},
		},
		[105791] = {--韩非池
			zone = 11, bossType = 2, eventInfo = {[706] = {born = nil, dead = 4}},
		},
		[105673] = {--伊夜
			zone = 11, bossType = 2, eventInfo = {[706] = {born = nil, dead = 3}},
		},
	},
}

function JX_CampData.GetGFBossTemplateID()
    return tZoneBossRelation
end


local tCastleBossTemplateID = {
    [30328] = true, -- 也斤沙赫
    [30329] = true, -- 阿努什加
    [30330] = true, -- 摩诃塔乞
    [30331] = true, -- 穆纳尔
    [30332] = true, -- 米谧奇
    [30333] = true, -- 何黑格赤
    [30334] = true, -- 火寻库姆
    [30335] = true, -- 伊本斯曼
    [30336] = true, -- 安息珍
    [30337] = true, -- 尉迟月
    [30338] = true, -- 呼延尼尼
    [30339] = true, -- 萨珊合敦
    [30340] = true, -- 希瓦察哈
    [30341] = true, -- 乌额蒙
    [30342] = true, -- 库都札兰
    [30343] = true, -- 哈懿玛
    [30344] = true, -- 哈贾余
    [30345] = true, -- 哈波伊
    [30346] = true, -- 哈尼斯
    [30347] = true, -- 康双韦
    [30348] = true, -- 石破奴
    [30349] = true, -- 史世高
    [30350] = true, -- 安穆克
    [30351] = true, -- 草江方
    [30310] = true, -- 恶人谷大将
    [30322] = true, -- 浩气盟大将
    [30519] = true, -- 莫雨
    [30562] = true, -- 穆玄英
    [123975] = true, -- 浩气盟大将·分线
    [123976] = true, -- 恶人谷大将·分线
    [100276] = true, -- 分线混分BOSS
    [100133] = true, -- 分线混分BOSS
}

function JX_CampData.GetCastleBossTemplateID()
    return tCastleBossTemplateID
end

local tShapeShiftID = { -- 部分载具玩家 "ui/Image/UITga/CommandUI02.UITex" 33 55 54
    [1]  = {class = 1, icon = 33}, -- 神机车-驾驶
    [2]  = {class = 1, icon = 33}, -- 神机车-战斗
    [3]  = {class = 2, icon = 55}, -- 神机台
    [4]  = {class = 3, icon = 54}, -- 摧城车-驾驶
    [5]  = {class = 3, icon = 54}, -- 摧城车-战斗

    [9]  = {class = 1, icon = 33}, -- 攻防神机车-驾驶
    [10] = {class = 1, icon = 33}, -- 攻防神机车-战斗
    [11] = {class = 2, icon = 55}, -- 攻防神机台
    [12] = {class = 3, icon = 54}, -- 攻防摧城车-驾驶
    [13] = {class = 3, icon = 54}, -- 攻防摧城车-战斗

    -- [40] = {class = 1, icon = 54}, -- 帮会联赛摧城车-驾驶
    -- [41] = {class = 1, icon = 54}, -- 帮会联赛摧城车-战斗
    -- [42] = {class = 3, icon = 33}, -- 帮会联赛神机车-驾驶
    -- [43] = {class = 3, icon = 33}, -- 帮会联赛神机车-战斗
    -- [44] = {class = 2, icon = 55}, -- 帮会联赛神机台
}

function JX_CampData.GetShapeShiftID()
    return tShapeShiftID
end

function JX_CampData.IsCastleBarnNpc(dwTemplateID) --粮仓
    return dwTemplateID >= 30101 and dwTemplateID <= 30200 or dwTemplateID >= 124260 and dwTemplateID <= 124279
end
function JX_CampData.IsCastleWorkshopNpc(dwTemplateID) --工坊
    return dwTemplateID >= 30201 and dwTemplateID <= 30300 or dwTemplateID >= 124280 and dwTemplateID <= 124300
end
function JX_CampData.IsCastleTowerNpc(dwTemplateID) --箭塔
    return dwTemplateID >= 29001 and dwTemplateID <= 30000 or dwTemplateID >= 124109 and dwTemplateID <= 124140
end

local tCampQuestTemplateID = {
    [110578] = true, -- 跨服烂柯山牛车
    [110579] = true, -- 跨服烂柯山牛车
    [47034]  = true, -- 黑戈壁牛车
    [47035]  = true, -- 黑戈壁牛车
    [56526]  = true, -- 大草原牛车
    [56527]  = true, -- 大草原牛车
	-- 跨服烂柯山关隘首领
    [111608] = true, -- 恶人1号
    [111609] = true, -- 恶人2号
    [111610] = true, -- 恶人3号
    [111605] = true, -- 浩气1号
    [111606] = true, -- 浩气2号
    [111607] = true, -- 浩气3号
	[111651] = true, -- 中立1号
    [111652] = true, -- 中立2号
    [111653] = true, -- 中立3号
	-- 跨服世界boss
	[110275] = true,
	[110184] = true,
	[110353] = true,
	[110450] = true,
	[100506] = true,
	[100509] = true,
	[105868] = true,
	[62770 ] = true,
	[62133 ] = true,
	[46766 ] = true,
	[46402 ] = true,
	[56922 ] = true,
	[57110 ] = true,
	[100817] = true,
	[100574] = true,
	[62110 ] = true,
	[62714 ] = true,
	[66980 ] = true,
	[46788 ] = true,
	[46792 ] = true,
	[57101 ] = true,
	[57100 ] = true,
	--战场
	[6620] = true, --九宫棋谷得分豆子
}

function JX_CampData.GetCampQuestTemplateID()
    return tCampQuestTemplateID
end

-- 帮会联赛相关的NPC
local tTongLeagueTemplateID = {
	-- [103254] = true, --城门
	-- [103348] = true, --城门开关
	-- [103358] = true, --摧城车
	-- [103363] = true, --神机车
	-- [103364] = true, --神机台
	-- [103392] = true, --大旗
	-- [103426] = true, --粮仓
	-- [103427] = true, --工坊
	-- [103428] = true, --阿甘
	-- [103440] = true, --复活点旗帜
	-- [103611] = true, --物资箱
	[128554] = true, --红大旗
	[128555] = true, --蓝大旗
	[128552] = true, --红一塔
	[128553] = true, --蓝一塔
	[128666] = true, --红二塔
	[128668] = true, --蓝二塔
	[128667] = true, --红三塔
	[128669] = true, --蓝三塔
	[128576] = true, --中立野怪麒麟

	[128556] = true, --小资源红方
	[128558] = true, --小资源蓝方
	[128557] = true, --大资源红方
	[128559] = true, --大资源蓝方
}

function JX_CampData.IsTongLeagueNpc(dwTemplateID)
    return tTongLeagueTemplateID[dwTemplateID]
end
