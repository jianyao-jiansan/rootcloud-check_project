#取集群服务器内存使用百分比
cat  >/tmp/free_info.sh <<'EOH'
free -m | sed -n '2p' | awk '{print "used mem is "$3"M,total mem is "$2"M,used percent is "$3/$2*100"%"}'
EOH
ansible  all -m copy -a  "src=/tmp/free_info.sh dest=/tmp/free_info.sh"
ansible all -m shell -a  "/bin/bash  /tmp/free_info.sh"|egrep  %
ansible all -m shell -a  "/bin/bash  /tmp/free_info.sh"|egrep  % >/tmp/free_info.log
b=$(cat  /tmp/free_info.log|wc  -l)
let  var=$(cat /tmp/free_info.log |awk   '{print  $NF}'|awk   -F '.' '{print  $1}'|xargs |sed  's/ /+/g')
#let  var=$(cat test.txt |awk   '{print  $NF}'|awk   -F '.' '{print  $1}'|xargs |sed  's/ /+/g')
#echo  $var
free_info=$(echo `awk 'BEGIN{printf "%.1f%%\n",('$var')/('$b')}'`)
#取集群cpu使用率最大的服务器百分比
cat  >/tmp/cpu_info.sh<<'EOS'
cpu_us=`vmstat | awk '{print $13}' | sed -n '$p'`
cpu_sy=`vmstat | awk '{print $14}' | sed -n '$p'`
cpu_id=`vmstat | awk '{print $15}' | sed -n '$p'`
cpu_sum=$(($cpu_us+$cpu_sy))
echo $cpu_sum%
EOS
ansible  all -m copy -a  "src=/tmp/cpu_info.sh dest=/tmp/cpu_info.sh"
ansible all -m shell -a  "/bin/bash  /tmp/cpu_info.sh"
ansible all -m shell -a  "/bin/bash  /tmp/cpu_info.sh"|egrep  % >/tmp/cpu_info.log
cpu_info=$(cat /tmp/cpu_info.log |egrep  [0-9]%|awk   '{print  $NF}'|awk  -F  .  '{print  $1}'|sort -t "%" -k1 -n |tail  -n 1)
#取集群占用比最大的服务器百分比
ansible  all  -m shell -a  "df -h  |egrep -v  \"k8s|pods| /dev| /boot| /run| /sys| /home| /var| ^/ \""|egrep  [0-9]%
disk_info=$(ansible  all  -m shell -a  "df -h  |egrep -v  \"k8s|pods| /dev| /boot| /run| /sys| /home| /var| ^/ \""|egrep  [0-9]%|awk   '{print  $5}'|sort -t "%" -k1 -n|tail  -n 1)

#K8S pod 检查开始
kubectlexit=$(kubectl version)
if [ -z "$kubectlexit" ];then
    echo "kubectl is not exited"
    exit 0
fi
echo "kubectl is exited "
k8sfile="/tmp/K8Sinfo.log"
k8s_restart="/tmp/k8s_restart.log"
restart_pod=""
unready_pod=""
unnormal_pod=""
unRuninginitpodinfo="test-job-connect|test-job-openapi|rook-ceph-osd-prepare-node|developer-kong|developer-internal-kong"
#K8S pod 信息写入文件
kubectl get po --all-namespaces|grep -v NAME >$k8sfile
#K8S 重启事件写入文件
kubectl get event --all-namespaces|grep Started >$k8s_restart

#解析文件 拿到发生重启事件的podname
while read line
do
    pod_name=$(echo "$line" |awk '{print $5}' |awk -F "/" '{print $2}')
    #restart_time=$(echo "$line" |awk '{print $2}'|grep -v "d")
    result=$(echo $restart_pod |grep "$pod_name")
    if [ -z "$result" ];then
        restart_pod="${restart_pod}${pod_name}\n"
    fi
done < $k8s_restart

#解析文件 拿到未完全准备以及未running的podname
while read line
do
    pod_name=$(echo "$line" | awk '{print $2}')
    pod_status=$(echo "$line" | awk '{print $4}')
    pod_readynum=$(echo "$line" | awk '{print $3}'|awk -F "/" '{print $1}')
    pod_allnum=$(echo "$line" | awk '{print $3}'|awk -F "/" '{print $2}')
    if [ "$pod_status" = "Running" ];then
        if [ "$pod_readynum" -ne "$pod_allnum" ];then
            unready_pod="${unready_pod}${pod_name}\n"
        fi
    else
        unrunninginfo=$(echo "$pod_name"|egrep -v "$unRuninginitpodinfo")
        if [ -n "$unrunninginfo" ];then
            unnormal_pod="${unnormal_pod}${pod_name}\n"
        fi
    fi
done < $k8sfile

#检查结果输出
echo "------------------------unrunning pod (异常的pod)-----------------------------------"
echo -e "$unnormal_pod"
echo "------------------------unready pod (未准备的pod)-----------------------------------"
echo -e "$unready_pod"
echo "-------------------------restart pod(重启过的pod)-----------------------------------"
echo -e "$restart_pod"


echo "------------------------K8S pod status(K8S 集群pod状态)------------------------------"
if [[ -z "$unnormal_pod" && -z "$unready_pod" ]];then
echo -e "ALL pod are OK\n"
else
echo -e "Some  pod  is unnormal\n"
fi
echo  "----------------------system base info (系统基础信息)-------------------------------"
echo  -e  "CPU：${cpu_info}\n\n内存：${free_info}\n\n磁盘：${disk_info}"