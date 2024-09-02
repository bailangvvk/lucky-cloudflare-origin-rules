本人的路由器是于咸鱼 旷佬 89(包邮) 购入1+8G 一下是本人的交流心得

1G是可以跑docker的 但是没有虚拟化 只能靠CPU纯算

我目前是用的V大的固件 fork以后使用云编译 https://github.com/bailangvvk/OpenWRT-CI-AX1800Pro

我的固件有lucky alist

光猫桥接 京东云亚瑟pppoe拨号
lucky STUN到外网映射端口 然后通过lucky自动义脚本同步到cloudflare的origin-rules端口 这样实现通过域名动态访问家里的路由器

lucky自动义脚本！！！需要安装jq拓展和curl！！！

https://raw.githubusercontent.com/bailangvvk/lucky-cloudflare-origin-rules/main/origin-rules.sh

rule_description需要改成的你的规则名

解答一下常见问题

## 1.很多人混淆了openwrt固件和istore固件 他们本质上是一样的 只不过istore固件是加了istoreX这个固件


## 2.很多固件是这样的 比如alist    alist是整个软件底包 而luci-app-alist是带有图像化的(luci-app-XXXX)都是 而带有luci-appXXXXi18n-zh-cn(意思就是翻译包) 因为官方immortalwrt的不带有luci-app-alist 所以你可能需要到kinndi9的源上下载
https://dl.openwrt.ai/23.05/packages/aarch64_cortex-a53/kiddin9/ 当然编译时你也可以用它的源来选择上面包编译某插件

## 3.很多人编译openwrt的IPQ6000固件失败比如AX1800Pro AX6600 但是找不到原因 是因为上游源吗的最大内存限制是1024M 我们可以添加以下代码
 ```bash
    echo "CONFIG_IPQ_MEM_PROFILE_1024=n" >> ./.config
   echo "CONFIG_IPQ_MEM_PROFILE_512=y" >> ./.config
   echo "CONFIG_ATH11K_MEM_PROFILE_1G=n" >> ./.config
   echo "CONFIG_ATH11K_MEM_PROFILE_512M=y" >> ./.config
   ```

改成1G那些没有影响的 超过512M他还是会乖乖调用的

# 插个小广
https://github.com/bailangvvk/OpenWRT-CI-AX1800Pro/tree/main
这上面简洁写了如何本地化编译 是fork原仓库 https://github.com/VIKINGYFY/OpenWRT-CI 感谢V大这问整合了齐全的NSS补丁
当然你也可以在github云编译 forkV大的仓库 然后点到Action > QCA-ALL > Run workflow


## 4.其实大致固件都一样 只不过看NSS加速 QWRT全面些 libwrt是雏形 V大的整合也是很全面的 6.1.100支持最好的是
这位哥的(叫他蛋炒饭哥)
也可以加群659931961获取
# 注意事项 因为很多刷的都是双分区GPT分区表 因为他的固件专门是对蛋分区管理做了优化 uboot也做了优化 进入uboot闪灯很快

这是注意事项

## 5.所有的openwrt都支持安装docker 只需要在页面手dockerman直接安装就行 很多人混淆了 没集成docker就是不支持 openwrt轻量化系统 除了吗某些需要编译进内核的插件 很多都能直接安装


## 6.(求助) 至于很多人说的刷入某某固件后wifi掉了 或是自动重启 这时候你要搞清楚是刷的哪款固件 在什么情况触发 你直接说出问题了 对于他人来理解太抽象了 你需要告知情况 有懂的佬自然会告诉你咋解决 怎么怎么试试 看看能不能解决

## 7.关于重刷系统插件数据的问题
你只需要定期保存某个插件的数据 下次重装时候数据把他放到对应路径就行 比如alist是/etc/alist lucky是/etc/lucky
