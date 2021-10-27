#!/bin/bash
#***********************************************
#Author:        蔡佳伟
#Mail:          jiawei.cai@rootcloud.com
#Version:       1.0
#Date:          2021-10-27
#FileName:      test.sh
#Description:   检查最近24小时Hadoop db_share数据库中表的partitions是否是按小时连续生成
#***********************************************

# Hadoop中存储冷数据对应的数据库名字
DATABASE_NAME=db_share
# 1小时对应的秒数
ONE_HOUR_SECONDS=3600


####### 获得对应数据库中存数据的表名 ######
get_tables_sql=$(cat << EOD
SHOW TABLES in ${DATABASE_NAME};
EOD
)
IFS=$'\n'
tables=(`/usr/bin/hive -nhive -phive -e "${get_tables_sql}" 2> /dev/null | awk '/type_/{print $2}'`)
echo "tables: ${tables[@]}"
# 如果返回的数组为空，直接打印信息并退出
if [ ${#tables[@]} -eq 0 ]
then 
    echo "----------------------------获取${DATABASE_NAME}表单列表失败----------------------------"
    echo "请检查hive能否连上Hadoop，检查${DATABASE_NAME}数据库是否存在表单"
    exit
fi
# 一般专属云只有一个表
table_name=${tables[-1]}
echo "table_name: $table_name"


###### 获取partition对应的小时id列表 ######
get_partitions_sql=$(cat << EOD
USE ${DATABASE_NAME};
SHOW PARTITIONS ${table_name};
EOD
)

# 定义需要获取最近partition id的个数
latest_partition_num=24
# partition_hour_ids 的值为从 1970 年 1 月 1 日 00:00:00 UTC 到目前为止的小时数
partition_hour_ids=(`hive -nhive -phive -e "${get_partitions_sql}" 2> /dev/null | awk '/partitionid/{print $2}' | tail -n ${latest_partition_num} | awk -F "=" '{print $2}'`)
echo "partition_hour_ids: ${partition_hour_ids[@]}"
# 如果返回partition id的数组为空，则判断Hadoop数据有丢失
if [ ${#partition_hour_ids[@]} -eq 0 ]
then 
    echo "-----------------------------获取partitions失败-----------------------------"
    echo "请检查hive能否连上Hadoop，检查 ${DATABASE_NAME}.${table_name} 是否存在 partitions"
    exit
fi

###### partition生成有一个小时的延迟，当前时间点只能看到1小时之前整点产生的partition ######
###### 如果最后一个partition对应的时间戳，小于当前时间对应2小时以前的时间戳，则判断Hadoop数据有丢失 ######
# 最近一个partition对应的时间戳
last_partition_timestamp=`expr ${partition_hour_ids[-1]} \* ${ONE_HOUR_SECONDS}`
# 获取相对当前时间，2小时之前的时间戳
current_timestamp=`date +%s`
last_2hour_timestamp=`expr ${current_timestamp} - 2 \* ${ONE_HOUR_SECONDS} `
if [ ${last_partition_timestamp} -lt ${last_2hour_timestamp} ]; 
then
    echo "----------------------------------Hadoop 数据不正常----------------------------------"
    echo "${DATABASE_NAME}.${table_name} 最近1小时以内的partition没有生成"
    exit
fi


###### 判断获取partition id对应的小时数据，是否是满足每次递增1小时；若不满足，则判断Hadoop数据有丢失 ######
# 保存数组的第一个数据，并删数组第一个数据
last_partition_hour_id=${partition_hour_ids[0]}
unset partition_hour_ids[0]
for current_partition_hour_id in ${partition_hour_ids[@]}
do
    expected_partition_hour_id=`expr ${last_partition_hour_id} + 1`
    if [ ${current_partition_hour_id} -ne ${expected_partition_hour_id} ]
    then
        echo "----------------------------------Hadoop 数据不正常----------------------------------"
        echo "${DATABASE_NAME}.${table_name} 的 partitions 缺失起始位置(含): partitionid=${current_partition_hour_id}"
        exit
    fi
    last_partition_hour_id=${current_partition_hour_id}
done


###### 如果上述检查都通过了，打印正常提示 ######
echo "----------------------------------Hadoop 数据正常-----------------------------------"
