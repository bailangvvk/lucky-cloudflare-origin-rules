#!/bin/sh

# 设置必要的变量
email="你的cloudflare邮箱"
api_key="你的cloudflare GLOBAL API KEY"
domain="lovelyy.us.kg"  # 主域名信息
rule_description="Openwrt Nginx cdn4 > port"  # 需要更新描述的规则
new_port=${port}  # 你想要设置的新端口默认是lucky传递的参数

# 锁文件路径
lockfile="/tmp/cloudflare_update.lock"

# 随机睡眠 0 到 1 秒
sleep_time=$(awk -v min=0 -v max=1000 'BEGIN{srand(); print int(min+rand()*(max-min+1))}')
sleep $(echo "scale=3; $sleep_time / 1000" | bc)

# 等待锁文件，最多等 20 秒
max_wait=20
wait_time=0

while [ -f "$lockfile" ]; do
  # 如果锁文件存在，等待1秒
  sleep 1
  wait_time=$((wait_time + 1))
  
  if [ "$wait_time" -ge "$max_wait" ]; then
    echo "等待锁文件释放超时，脚本退出。"
    exit 1
  fi
done

# 创建锁文件
touch "$lockfile"

# 捕获脚本退出时删除锁文件
trap 'rm -f "$lockfile"' EXIT

# 获取 zone_id
zone_id=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=${domain}" \
-H "X-Auth-Email: ${email}" \
-H "X-Auth-Key: ${api_key}" \
-H "Content-Type: application/json" | jq -r '.result[0].id')

# 获取所有规则集
rulesets=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${zone_id}/rulesets" \
-H "X-Auth-Email: ${email}" \
-H "X-Auth-Key: ${api_key}" \
-H "Content-Type: application/json")

# 提取 HTTP 请求原点规则集的 ID
ruleset_id=$(echo "$rulesets" | jq -r '.result[] | select(.phase == "http_request_origin") | .id')

# 获取 ruleset 的详细信息
ruleset_response=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${zone_id}/rulesets/${ruleset_id}" \
  -H "X-Auth-Email: ${email}" \
  -H "X-Auth-Key: ${api_key}" \
  -H "Content-Type: application/json")

# 提取所有规则
rules=$(echo "$ruleset_response" | jq -r '.result.rules')

# 找到需要更新的规则 ID
rule_id=$(echo "$rules" | jq -r --arg description "$rule_description" '.[] | select(.description == $description) | .id')

# 创建更新后的规则列表
updated_rules=$(echo "$rules" | jq --arg id "$rule_id" --argjson port "$new_port" '
  map(
    if .id == $id then
      .action_parameters.origin.port = $port
    else
      .
    end
  )
')

# 更新规则中的端口
update_response=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/${zone_id}/rulesets/${ruleset_id}" \
  -H "X-Auth-Email: ${email}" \
  -H "X-Auth-Key: ${api_key}" \
  -H "Content-Type: application/json" \
  --data "{
    \"rules\": $updated_rules
  }")

# 检查更新响应
# if echo "$update_response" | jq -e '.success' > /dev/null; then
#   echo "规则端口已成功更新为 ${new_port}。"
# else
#   echo "更新规则端口时出现错误:"
#   echo "$update_response" | jq .
#   exit 1
# fi

# 脚本执行完毕，锁文件自动删除
