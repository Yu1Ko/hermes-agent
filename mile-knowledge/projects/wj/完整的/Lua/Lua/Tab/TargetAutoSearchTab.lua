--*************************************** 工具生成，技能/技能UI ***************************************

--- 配置数据结构描述
local _TargetAutoSearchTab = {
	bDisableSearch = false, -- 是否禁止自动搜索目标
	bDefaultSelf = false,   -- 如果没有搜索到目标是否选择自己
	nFov = 360,             -- 搜索角色视野范围（角色面向角度°）
	nDistance = 5,          -- 搜索目标离自身最远距离
	nHeightDiff = 5,        -- 搜索目标离自身的高度差
	nLockedDistance = 8,   -- 锁定的目标离开自身距离以后失去目标
}

local tConfigs =
{
	[1] =
	{
		[100406] =
		{
			bEnemy = true,
			nFov = 360,
			nDistance = 20,
			nHeightDiff = 20,
			nLockedDistance = 30
		},
		[100407] =
		{
			bEnemy = true,
			nFov = 360,
			nDistance = 20,
			nHeightDiff = 20,
			nLockedDistance = 30
		}
	},
	[2] =
	{
		[100389] =
		{
			bEnemy = true,
			nFov = 360,
			nDistance = 20,
			nHeightDiff = 20,
			nLockedDistance = 30
		},
		[100398] =
		{
			bEnemy = true,
			nFov = 360,
			nDistance = 20,
			nHeightDiff = 20,
			nLockedDistance = 30
		}
	},
	[3] =
	{
		[100053] =
		{
			bEnemy = true,
			nFov = 360,
			nDistance = 20,
			nHeightDiff = 20,
			nLockedDistance = 30
		},
		[100069] =
		{
			bEnemy = true,
			nFov = 360,
			nDistance = 20,
			nHeightDiff = 20,
			nLockedDistance = 30
		}
	},
	[4] =
	{
		[100408] =
		{
			bEnemy = true,
			nFov = 360,
			nDistance = 20,
			nHeightDiff = 20,
			nLockedDistance = 30
		},
		[100411] =
		{
			bDisableSearch = true
		}
	},
	[5] =
	{
		[100409] =
		{
			bDisableSearch = true
		},
		[100410] =
		{
			bEnemy = true,
			nFov = 360,
			nDistance = 20,
			nHeightDiff = 20,
			nLockedDistance = 30
		}
	},
	[6] =
	{
		[100725] =
		{
			bEnemy = true,
			nFov = 360,
			nDistance = 20,
			nHeightDiff = 20,
			nLockedDistance = 30
		},
		[100726] =
		{
			bEnemy = true,
			nFov = 360,
			nDistance = 20,
			nHeightDiff = 20,
			nLockedDistance = 30
		}
	},
	[8] =
	{
		[100654] =
		{
			bEnemy = true,
			nFov = 360,
			nDistance = 20,
			nHeightDiff = 20,
			nLockedDistance = 30
		},
		[100655] =
		{
			bDisableSearch = true
		}
	},
	[9] =
	{
		[100636] =
		{
			bEnemy = true,
			nFov = 360,
			nDistance = 20,
			nHeightDiff = 20,
			nLockedDistance = 25
		},
		[100638] =
		{
			bEnemy = true,
			nFov = 360,
			nDistance = 20,
			nHeightDiff = 20,
			nLockedDistance = 25
		},
		[101716] =
		{
			bEnemy = true,
			nFov = 360,
			nDistance = 20,
			nHeightDiff = 20,
			nLockedDistance = 30
		},
		[101734] =
		{
			bEnemy = true,
			nFov = 360,
			nDistance = 20,
			nHeightDiff = 20,
			nLockedDistance = 30
		}
	},
	[10] =
	{
		[100618] =
		{
			bEnemy = true,
			nFov = 360,
			nDistance = 20,
			nHeightDiff = 20,
			nLockedDistance = 30
		},
		[100631] =
		{
			bEnemy = true,
			nFov = 360,
			nDistance = 20,
			nHeightDiff = 20,
			nLockedDistance = 30
		}
	},
	[11] =
	{
		[100651] =
		{
			bEnemy = true,
			nFov = 360,
			nDistance = 20,
			nHeightDiff = 20,
			nLockedDistance = 30
		}
	},
	[12] =
	{
		[101024] =
		{
			bEnemy = true,
			nFov = 360,
			nDistance = 20,
			nHeightDiff = 20,
			nLockedDistance = 30
		},
		[101025] =
		{
			bEnemy = true,
			nFov = 360,
			nDistance = 20,
			nHeightDiff = 20,
			nLockedDistance = 30
		}
	},
	[13] =
	{
		[101124] =
		{
			bEnemy = true,
			nFov = 360,
			nDistance = 20,
			nHeightDiff = 20,
			nLockedDistance = 30
		},
		[101125] =
		{
			bDisableSearch = true
		}
	},
	[14] =
	{
		[100994] =
		{
			bEnemy = true,
			nFov = 360,
			nDistance = 20,
			nHeightDiff = 20,
			nLockedDistance = 30
		}
	},
	[15] =
	{
		[101090] =
		{
			bEnemy = true,
			nFov = 360,
			nDistance = 20,
			nHeightDiff = 20,
			nLockedDistance = 30
		}
	},
	[16] =
	{
		[101173] =
		{
			bEnemy = true,
			nFov = 360,
			nDistance = 20,
			nHeightDiff = 20,
			nLockedDistance = 30
		}
	},
	[17] =
	{
		[101450] =
		{
			bEnemy = true,
			nFov = 360,
			nDistance = 20,
			nHeightDiff = 20,
			nLockedDistance = 30
		}
	},
	[18] =
	{
		[101355] =
		{
			bEnemy = true,
			nFov = 360,
			nDistance = 20,
			nHeightDiff = 20,
			nLockedDistance = 30
		},
		[101374] =
		{
			bDisableSearch = true
		}
	},
	[19] =
	{
		[101375] =
		{
			bEnemy = true,
			nFov = 360,
			nDistance = 20,
			nHeightDiff = 20,
			nLockedDistance = 30
		}
	},
	[20] =
	{
		[101740] =
		{
			bEnemy = true,
			nFov = 360,
			nDistance = 20,
			nHeightDiff = 20,
			nLockedDistance = 30
		}
	},
	[21] =
	{
		[102278] =
		{
			bEnemy = true,
			nFov = 360,
			nDistance = 20,
			nHeightDiff = 20,
			nLockedDistance = 30
		}
	},
	[22] =
	{
		[102393] =
		{
			bEnemy = true,
			nFov = 360,
			nDistance = 20,
			nHeightDiff = 20,
			nLockedDistance = 30
		}
	},
	[10001] =
	{
		[100001] =
		{
			bDisableSearch = true
		},
		[100002] =
		{
			nFov = 360,
			nDistance = 200,
			nHeightDiff = 200,
			nLockedDistance = 200
		}
	}
}
return tConfigs
