# check_project
| 脚本名称           | 说明                                                         |
| ------------------ | ------------------------------------------------------------ |
| system_info.sh     | 检测K8S集群系统 CPU、内存、磁盘使用率，以及pod状态           |
| hive_partitions.sh | 检查最近24小时Hive db_share数据库中表的partitions，是否是按小时连续生成 |
|                    |                                                              |




## 使用指南

#### 项目使用条件

| 脚本名称           | 前提条件                                                     |
| ------------------ | ------------------------------------------------------------ |
| system_info.sh     | 脚本放置到kubernetes节点上；节点部署了ansible工具，并配置好节点间通信免密; |
| hive_partitions.sh | 脚本放置到Hive节点上运行，需要使用hive命令                   |
|                    |                                                              |

#### 安装

上传脚本到对应的Linux节点上



#### 使用示例

###### system_info.sh

~~~bash
[root@node01 ~]# bash system_info.sh
used mem is 78533M, total mem is 93472M, used percent is 84.0177%
used mem is 64829M, total mem is 93472M, used percent is 69.3566%
used mem is 73655M, total mem is 93472M, used percent is 78.799%
node02 | CHANGED | rc=0 >>
6%
node03 | CHANGED | rc=0 >>
7%
node01 | CHANGED | rc=0 >>
5%
/dev/vda1                     99G   17G   78G  18% /
/dev/mapper/vgdata2-lvdata2  4.0T  110G  3.9T   3% /data2
/dev/mapper/vgdata1-lvdata1  100G   67G   34G  67% /soft
/dev/mapper/vgdata3-lvdata3  1.0T   91G  933G   9% /data
/dev/vda1                     99G   34G   61G  37% /
/dev/mapper/vgdata2-lvdata2  4.0T  112G  3.9T   3% /data2
/dev/mapper/vgdata3-lvdata3  1.0T   88G  937G   9% /data
/dev/mapper/vgdata1-lvdata1  100G   33G   68G  33% /soft
/dev/mapper/vgdata4-lvdata4  1.0T  414M  1.0T   1% /backup
/dev/vda1                     99G   37G   58G  39% /
/dev/mapper/vgdata2-lvdata2  4.0T  124G  3.9T   4% /data2
/dev/mapper/vgdata1-lvdata1  100G   75G   26G  75% /soft
/dev/mapper/vgdata3-lvdata3  1.0T   88G  936G   9% /data
kubectl is exiting
------------------------unrunning pod (异常的pod)-----------------------------------
internal-kong-routeinit-job-vdhzf
kong-routeinit-job-xvzcs

------------------------unready pod (未准备的pod)-----------------------------------

-------------------------restart pod(重启过的pod)-----------------------------------

------------------------K8S pod status(K8S 集群pod状态)------------------------------
Some pod is unnormal

----------------------system base info (系统基础信息)-------------------------------
CPU：7%

内存：77.0%

磁盘：75%
~~~

###### hive_partitions.sh

~~~bash
[root@node01 ~]# bash hive_partitions.sh
----------------------------------Hive Partitions 数据正常-----------------------------------
~~~



## 部署方法

上传脚本至现网kubernetes节点node01的/root目录下。



## 常见问题

#### 问题：运行shell脚本，遇到"$'\r': command not found"

- 分析：这是由于shell脚本文件在Windows环境编辑，使用的Windows换行符

- 解决：在Window环境，提交shell脚本到Gitlab之前，使用`dos2unix XXX.sh`转化文本格式为Unix格式



## 贡献指南
如需更新脚本，请联系作者一起更新。




## 版本历史




## 关于作者

* system_info.sh - [邓宾](mailto:bin.deng@rootcloud.com)
* hive_partitions.sh - [蔡佳伟](mailto:jiawei.cai@rootcloud.com)



## 授权协议

# rootcloud-check_project
# rootcloud-check_project
# rootcloud-check_project
# rootcloud-check_project
# rootcloud-check_project
