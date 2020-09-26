# SouceModPlugins For L4D2
**L4D2 服务器搭建（Linux）**

之前 Windows 的：https://www.jianshu.com/p/52c1635876e7

没错，没钱续费了，干脆重新搞个 Linux 放家里

## 安装 SteamCMD
https://developer.valvesoftware.com/wiki/SteamCMD#Linux
```
dpkg --add-architecture i386
apt update
apt install lib32gcc1 -y
apt install steamcmd -y
```

## 安装/更新服务器
运行 `steamcmd`

```
login anonymous
force_install_dir /data/syncthing/L4D2Server
app_update 222860 validate
quit
```

其中 `/data/syncthing/L4D2Server` 为下载路径

## SourceMod、Metamod、L4DToolZ 插件
### 下载
#### SourceMod
SourceMod 官网：https://www.sourcemod.net/

SourceMod 稳定版下载：https://www.sourcemod.net/downloads.php?branch=stable

当然下载 Linux 版的

#### Metamod
Metamod官网：https://www.sourcemm.net/

当然不要忘记生成对应游戏的VDF文件：https://www.sourcemm.net/vdf

#### L4DToolZ
L4DToolZ：https://forums.alliedmods.net/showthread.php?t=93600

L4DToolZ的GitHub：https://github.com/ivailosp/l4dtoolz/

L4D2的是下1.0.0.9h版本

**总共是4份文件**

### 安装

~~安装顺序是无所谓的~~

#### Metamod
将 `mmsource-1.10.7-git970-linux.tar.gz` 的addons解压出来与 `./left4dead2/addons/` 合并

再将之前生成的 `metamod.vdf` 覆盖addons里的 `metamod.vdf` ~~（这个文件其实就是个路径设置）~~

#### SourceMod
同理将 `sourcemod-1.9.0-git6281-linux.tar.gz` 里的 `addons` 和 `cfg` 与`./left4dead2/addons/`和 `./left4dead2/cfg/` 合并

#### L4DToolZ
将 `l4dtoolz(L4D2)-1.0.0.9h.zip` 里的两个文件夹 `l4dtoolz` 和 `metamod` 放到 `./left4dead2/addons/` 里。

### 简单运行
`./srcds_run -game left4dead2 -insecure +maxplayers 16 +hostport 27015 +map c1m2_streets`

命令行参数详见：https://developer.valvesoftware.com/wiki/Command_Line_Options

在 Console 里输入 `meta list`
```
meta list
Listing 3 plugins:
  [01] SourceMod (1.10.0.6497) by AlliedModders LLC
  [02] L4DToolZ (1.0.0.9h-2-g7465d71b-dirty) by Ivailosp
  [03] SDK Tools (1.10.0.6497) by AlliedModders LLC
```
像这样就安装成功了

### 简单更改服务器最大人数
输入命令：

`sm_cvar sv_maxplayers 16;sm_cvar sv_visiblemaxplayers 16`

当然这些命令可以预先放到 `./left4dead2/cfg/server.cfg` 里。

### 简单设置权限
* 在 `./left4dead2/addons/sourcemod/configs/admins_simple.ini` 里的增加一行

`"STEAM_1:1:125637774"     "99:z" "passwd"`

第一个引号是 steamID 或者是 Steam 个人资料名(游戏里的名字)；第二个引号是权限大小；第三个引号是密码。具体说明文件里都有。

* 然后到同一目录下的`core.cfg`里修改

`"PassInfoVar"			"_password"`

* 想要成功获得服务器的权限还要在进游戏前在游戏的控制台输入

`setinfo _password passwd`

当然可以放进你游戏目录里的 `./left4dead2/cfg/autoexec.cfg` 里，这样每次运行游戏时就会自动执行这条命令

### 服务器欢迎界面设置
大图：`./left4dead2/motd.txt`

小图：`./left4dead2/host.txt`

### SourceMod 插件安装
一般到 http://www.sourcemod.net/plugins.php 搜索下载，按照作者说明来就行了

推荐下载源码自己用 `./left4dead2/addons/sourcemod/scripting/compile.sh` 编译

这里用 `gettickrate` 插件演示

* 找到插件并下载源码 https://forums.alliedmods.net/showthread.php?p=649755
* 将 `tickrate.sp` 放入 `./left4dead2/addons/sourcemod/scripting/` 里
* 运行 `./compile.sh tickrate.sp` ，插件编译成功后会在 `compiled` 文件夹里生成 `tickrate.smx`
* 将 `tickrate.smx` 放到 `./left4dead2/addons/sourcemod/plugins/` 里就算安装成功了
* 有些插件需要放 `data` 到指定文件夹（往往是放同时兼容 Windows/Linux 服务器的参数），自己认真看作者的插件说明。
* 一般要服务器运行一次后自动生成该插件所需cfg文件到 `./left4dead2/cfg/sourcemod/`。当然这个插件功能简单就没有生成~

输入 `sm_gettickrate`，得到返回
```
The server tickrate is 29
```

当然你可以修改 `compile.sh` 直接编译生成到 `plugins` 里

#### 服务器Tickrate修改
上次搞 Windows 服务器的时候是2017年1月，没想到论坛7月份就有接盘侠搞了个新的：
https://forums.alliedmods.net/showthread.php?t=299669

下载 `tickrate_enabler.zip`

* 将对应文件解压放入 `addons` 文件夹
* 运行时加上参数 `-tickrate 100`

别忘 `server.cfg` 加上几个参数，比如 `sv_minrate、sv_maxrate、sv_maxupdaterate、sv_maxcmdrate、fps_max` 之类的

输入 `sm_gettickrate`，得到返回
```
The server tickrate is 100
```

#### 修改服务器名为中文名
https://github.com/HMBSbige/SouceModPlugins/blob/master/scripting/hostname.sp

上面一样的方法下载编译插件,之后直接在 `/left4dead2/addons/sourcemod/configs/hostname/hostname.txt`
修改，保存为UTF-8，好像无所谓带不带BOM

#### 修复 Steam 组链接错误

组 ID 大于 16777216 的话进入服务器显示封面跳转的链接会跳转到错误的组，熟悉这个数字的朋友一看就知道为什么了

https://github.com/HMBSbige/SouceModPlugins/blob/master/scripting/sv_steamgroup_fixer.sp

#### 其他自用插件
插件名|下载链接|描述
-|-|-
Melee In The Saferoom|https://forums.alliedmods.net/showthread.php?p=1160193|安全屋生成近战
Survivor Animation Fix Pack|https://forums.alliedmods.net/showthread.php?p=2340392|需要 DHOOKS;可能不需要此插件了
Advertisements|https://forums.alliedmods.net/showthread.php?p=592536|
Director Controller (All4Dead)|https://forums.alliedmods.net/showthread.php?p=751952|自用 https://github.com/HMBSbige/SouceModPlugins/blob/master/scripting/all4dead2.sp
Friendly-Fire Toolkit Lite|https://github.com/HMBSbige/SouceModPlugins/blob/master/scripting/fftlite.sp|反伤插件
Infinite-Jumping|https://github.com/chanz/infinite-jumping|连跳、多段跳，编译需要 https://github.com/bcserv/smlib
L4D2 Friendly-Fire info|https://github.com/HMBSbige/SouceModPlugins/blob/master/scripting/l4d2_friendlyfireinfo.sp|显示友伤信息
Gear Transfer|https://forums.alliedmods.net/showthread.php?p=1294082|R 键给物品、Bot自动给物品
Infected Health Gauge (Tank & Witch & Special)|https://forums.alliedmods.net/showthread.php?p=1167221|显示特感伤害
Night Vision|https://forums.alliedmods.net/showthread.php?p=1534293|双击F夜视
Randomize Tank Witch HP and Speed|https://forums.alliedmods.net/showthread.php?p=1076665|更改 Tank、Witch 的血量和移速
Stuck Zombie Melee Fix|https://forums.alliedmods.net/showthread.php?p=932416|Bug 修复
Survivor Identity Fix for 5+ Survivors|https://forums.alliedmods.net/showpost.php?p=2718792&postcount=36|Bug 修复，需要 [DHooks extension with detour support](https://forums.alliedmods.net/showpost.php?p=2588686&postcount=589)
自杀插件|https://forums.alliedmods.net/showthread.php?p=2107510|输入 !kill 或者 !explode 自杀
Riot Cop (and Fallen Survivor) Head Shot|https://forums.alliedmods.net/showthread.php?p=1626951|城管正面爆头可击杀
self stand up|https://forums.alliedmods.net/showthread.php?p=1795311|倒地自起，与 l4d_incapcrawl 插件冲突
Survivor AI Trigger fix|https://forums.alliedmods.net/showthread.php?p=1004836|全 Bot 队伍
Upgrade Pack Fixes|https://forums.alliedmods.net/showthread.php?p=2690901|多人配件 Bug 修复
Weapon Unlock|https://forums.alliedmods.net/showthread.php?p=1041458|武器解锁已经不需要了，但可以修改伤害
Survivor_AFK_Fix|https://forums.alliedmods.net/showthread.php?p=2714236|AFK BUG 修复，需要 [DHooks extension with detour support](https://forums.alliedmods.net/showpost.php?p=2588686&postcount=589)
MultiSlots|https://forums.alliedmods.net/showpost.php?p=2715546&postcount=249|多人 Bot 管理
Character Select Menu|https://forums.alliedmods.net/showthread.php?t=107121|换角色或者外观
白给插件|https://github.com/HMBSbige/SouceModPlugins/blob/master/scripting/wdnmd.sp|反编译望夜的 rygive.smxs，还需要放置 gamedata
玩家进入离开提示|https://github.com/HMBSbige/SouceModPlugins/blob/master/scripting/playerinfo.sp|
defib-fix|https://github.com/Satanic-Spirit/defib-fix|修复电击器电错人的 bug
8+ players Bug Fixes|https://github.com/Satanic-Spirit/l4d2_bugfixes|修复生还者分数统计 Bug 和 Witch 攻击错人的bug
Survivor Bot AI SHOOT IT FFS Fix|https://forums.alliedmods.net/showthread.php?p=893326|修复求生之路的人工智障
Weapon Drop|https://forums.alliedmods.net/showthread.php?t=123098|主动丢武器
kill_counter|https://github.com/HMBSbige/SouceModPlugins/blob/master/scripting/kill_counter.sp|击杀统计
MapControl|https://github.com/HMBSbige/SouceModPlugins/blob/master/scripting/l4d2_mapcontrol.sp|换图
