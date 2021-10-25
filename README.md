# check_project
system_info
检测K8S集群系统 CPU、内存、磁盘使用率，以及pod状态


## 使用指南

将节点放在kubernetes节点上，通过root用户直接执行命令： sh system_info.sh


#### 项目使用条件

前提条件：

1. 节点部署了ansible工具，并配置好节点间通信免密
2. ansible 可通过yum进行下载

#### 安装

OS X & Linux:

```sh
sh system_info.sh
```

#### 使用示例

~~~sh
[root@node01 ~]# sh system_info.sh 
kubectl is exited 
------------------------unrunning pod (异常的pod)-----------------------------------
iothub-persistent-hive-realtime-6ff8b674c7-wc6q6
iothub-persistent-hive-recoup-ff6bff6ff-f4k6h

------------------------unready pod (未准备的pod)-----------------------------------

-------------------------restart pod(重启过的pod)-----------------------------------

------------------------K8S pod status(K8S 集群pod状态)------------------------------
Some  pod  is unnormal

----------------------system base info (系统基础信息)-------------------------------
CPU：3%

内存：37.3%

磁盘：51%
~~~


## 部署方法

上传脚本至现网kubernetes节点node01的/root目录下。

## 常见问题

暂无
## 贡献指南
清阅读 [CONTRIBUTING.md](#) 了解如何向这个项目贡献代码。


## 版本历史

* 0.2.1
    * CHANGE: Update docs
* 0.2.0
    * CHANGE: Remove `README.md`
* 0.1.0
    * Work in progress


## 关于作者

* **XXX** - *Initial work*

查看更多关于这个项目的贡献者，请阅读 [contributors](#) 。


## 授权协议（可选）

这个项目 MIT 协议， 请点击 [LICENSE.md](LICENSE.md) 了解更多细节。

