
#!/bin/sh

# 设置必要的变量
email="你的cloudflare邮箱"
api_key="你的cloudflare GLOBAL API KEY"
domain="xxxx.us.kg"  # 主域名信息
rule_description="Openwrt Nginx cdn4 > port"  # 需要更新描述的规则
new_port=${port}  # 你想要设置的新端口，默认是传递的参数

# 缓存文件路径，拼接域名以区分不同域名
cache_dir="/tmp/cloudflare_origin_${domain}"
zone_id_cache="${cache_dir}/zone_id.cache"
ruleset_id_cache="${cache_dir}/ruleset_id.cache"

# 创建缓存目录
mkdir -p "$cache_dir"

# 获取 zone_id（使用缓存）
if [ -f "$zone_id_cache" ]; then
  zone_id=$(cat "$zone_id_cache")
else
  zone_id=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=${domain}" \
    -H "X-Auth-Email: ${email}" \
    -H "X-Auth-Key: ${api_key}" \
    -H "Content-Type: application/json" | jq -r '.result[0].id')
  echo "$zone_id" > "$zone_id_cache"
fi

# 获取 ruleset_id（使用缓存）
if [ -f "$ruleset_id_cache" ]; then
  ruleset_id=$(cat "$ruleset_id_cache")
else
  rulesets=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${zone_id}/rulesets" \
    -H "X-Auth-Email: ${email}" \
    -H "X-Auth-Key: ${api_key}" \
    -H "Content-Type: application/json")
  ruleset_id=$(echo "$rulesets" | jq -r '.result[] | select(.phase == "http_request_origin") | .id')
  echo "$ruleset_id" > "$ruleset_id_cache"
fi

# 获取 ruleset 的详细信息
ruleset_response=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${zone_id}/rulesets/${ruleset_id}" \
  -H "X-Auth-Email: ${email}" \
  -H "X-Auth-Key: ${api_key}" \
  -H "Content-Type: application/json")

# 提取所有规则
rules=$(echo "$ruleset_response" | jq -r '.result.rules')

# 找到需要更新的规则 ID
rule_id=$(echo "$rules" | jq -r --arg description "$rule_description" '.[] | select(.description == $description) | .id')

# 检查是否找到 rule_id
if [ -z "$rule_id" ]; then
  echo "未找到描述为 '${rule_description}' 的规则。"
  exit 1
fi

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
if echo "$update_response" | jq -e '.success' > /dev/null; then
  echo "规则端口已成功更新为 ${new_port}。"
else
  echo "更新规则端口时出现错误:"
  echo "$update_response" | jq .
  exit 1
fi
