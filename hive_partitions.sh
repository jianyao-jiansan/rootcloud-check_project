#!/bin/bash
#***********************************************
#Author:        蔡佳伟
#Mail:          jiawei.cai@rootcloud.com
#Version:       1.0
#Date:          2021-10-27
#FileName:      test.sh
#Description:   检查最近24小时Hive db_share数据库中表的partitions是否是按小时连续生成
#***********************************************

# Hive中存储冷数据对应的数据库名字
HIVE_DATABASE=db_share
HIVE_USERNAME=hive
HIVE_PASSWORD=hive
# 1小时对应的秒数
ONE_HOUR_SECONDS=3600

# 检查hive命令是否存在
HIVE_CMD=/usr/bin/hive
type ${HIVE_CMD} > /dev/null 2>&1 || { echo >&2 "命令 ${HIVE_CMD} 不存在，脚本退出。"; exit 1;}


####### 获得对应数据库中存数据的表名 ######
get_tables_sql=$(cat << EOD
SHOW TABLES in ${HIVE_DATABASE};
EOD
)
IFS=$'\n'
tables=(`${HIVE_CMD} -n${HIVE_USERNAME} -p${HIVE_USERNAME} -e "${get_tables_sql}" 2> /dev/null | awk '/type_/{print $2}'`)
#echo "tables: ${tables[@]}"
# 如果返回的数组为空，直接打印信息并退出
if [ ${#tables[@]} -eq 0 ]
then
    echo "----------------------------获取${HIVE_DATABASE}表单列表失败----------------------------"
    echo "请检查能否连上hiveserver2；检查${HIVE_DATABASE}数据库是否存在表单"
    exit
fi
# 一般专属云只有一个表
table_name=${tables[-1]}
#echo "table_name: $table_name"


###### 获取partition对应的小时id列表 ######
get_partitions_sql=$(cat << EOD
USE ${HIVE_DATABASE};
SHOW PARTITIONS ${table_name};
EOD
)

# 定义需要获取最近partition id的个数
latest_partition_num=24
# partition_hour_ids 的值为从 1970 年 1 月 1 日 00:00:00 UTC 到目前为止的小时数
partition_hour_ids=(`${HIVE_CMD} -n${HIVE_USERNAME} -p${HIVE_USERNAME} -e "${get_partitions_sql}" 2> /dev/null | awk '/partitionid/{print $2}' | tail -n ${latest_partition_num} | awk -F "=" '{print $2}'`)
#echo "partition_hour_ids: ${partition_hour_ids[@]}"
# 如果返回partition id的数组为空，则判断hive partitions数据有丢失
if [ ${#partition_hour_ids[@]} -eq 0 ]
then
    echo "-----------------------------获取partitions失败-----------------------------"
    echo "请检查能否连上hiveserver2；检查 ${HIVE_DATABASE}.${table_name} 是否存在 partitions"
    exit
fi

###### partition生成有一个小时的延迟，当前时间点查看上一个整点小时产生的partition ######
###### 如果最后一个partition对应的时间戳，小于当前时间对应2小时以前的时间戳，则判断hive partitions数据有丢失 ######
# 最近一个partition对应的时间戳
last_partition_timestamp=`expr ${partition_hour_ids[-1]} \* ${ONE_HOUR_SECONDS}`
# 获取相对当前时间，2小时之前的时间戳
current_timestamp=`date +%s`
last_2hour_timestamp=`expr ${current_timestamp} - 2 \* ${ONE_HOUR_SECONDS} `
if [ ${last_partition_timestamp} -lt ${last_2hour_timestamp} ];
then
    echo "----------------------------------Hive Partitions 数据不正常----------------------------------"
    echo "${HIVE_DATABASE}.${table_name} 上一个整点小时partition没有生成"
    echo "最近一个 partition id 对应的时间戳: ${last_partition_timestamp}"
    exit
fi


###### 判断获取partition id对应的小时数据，是否是满足每次递增1小时；若不满足，则判断hive partitions数据有丢失 ######
# 保存数组的第一个数据，并删数组第一个数据
last_partition_hour_id=${partition_hour_ids[0]}
unset partition_hour_ids[0]
for current_partition_hour_id in ${partition_hour_ids[@]}
do
    expected_partition_hour_id=`expr ${last_partition_hour_id} + 1`
    if [ ${current_partition_hour_id} -ne ${expected_partition_hour_id} ]
    then
        echo "----------------------------------Hive Partitions 数据不正常----------------------------------"
        echo "${HIVE_DATABASE}.${table_name} 的 partitions 缺失起始位置(含): partitionid=${current_partition_hour_id}"
        exit
    fi
    last_partition_hour_id=${current_partition_hour_id}
done


###### 如果上述检查都通过了，打印正常提示 ######
echo "----------------------------------Hive Partitions 数据正常-----------------------------------"
