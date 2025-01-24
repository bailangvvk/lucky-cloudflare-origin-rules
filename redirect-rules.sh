# 设置必要的变量
# 你的cf账号
email="你的邮箱"
# 你的全局API_KEY
api_key="你的全局API KEY"
# 主域名信息
domain="xxx.us.kg"
# 需要更新描述的规则名称 （必需）
rule_description="openwrt"
# 动态设置的 IP 地址
ipAddr=${ipAddr}
# 重定向域名信息
redirect_domain="op."$domain

# 缓存文件路径
cache_dir="/tmp/cloudflare_cache"
zone_id_cache="${cache_dir}/zone_id_${domain}.cache"
ruleset_id_cache="${cache_dir}/ruleset_id_${domain}.cache"
rule_id_cache="${cache_dir}/rule_id_${domain}_${rule_description}.cache"

# 创建缓存目录（如果不存在）
mkdir -p "$cache_dir"

# 获取 zone_id（使用缓存）
if [ -f "$zone_id_cache" ]; then
  zone_id=$(cat "$zone_id_cache")
else
  zone_id=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=${domain}" \
    -H "X-Auth-Email: ${email}" \
    -H "X-Auth-Key: ${api_key}" \
    -H "Content-Type: application/json" | jq -r '.result[0].id')
#   echo "$zone_id" > "$zone_id_cache"
fi

# echo "Zone ID: $zone_id"

# 获取 ruleset_id（使用缓存）
if [ -f "$ruleset_id_cache" ]; then
  ruleset_id=$(cat "$ruleset_id_cache")
else
  ruleset_id=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${zone_id}/rulesets" \
    -H "X-Auth-Email: ${email}" \
    -H "X-Auth-Key: ${api_key}" \
    -H "Content-Type: application/json" | \
    jq -r '.result[] | select(.phase == "http_request_dynamic_redirect") | .id')
#   echo "$ruleset_id" > "$ruleset_id_cache"
fi

# echo "Ruleset ID: $ruleset_id"

# 获取 rule_id（使用缓存）
if [ -f "$rule_id_cache" ]; then
  rule_id=$(cat "$rule_id_cache")
else
  rule_id=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${zone_id}/rulesets/${ruleset_id}" \
    -H "X-Auth-Email: ${email}" \
    -H "X-Auth-Key: ${api_key}" \
    -H "Content-Type: application/json" | \
    jq -r ".result.rules[] | select(.description == \"${rule_description}\") | .id")
#   echo "$rule_id" > "$rule_id_cache"
fi

# echo "Rule ID: $rule_id"

# 更新规则
response=$(curl -s -X PATCH "https://api.cloudflare.com/client/v4/zones/${zone_id}/rulesets/${ruleset_id}/rules/${rule_id}" \
    -H "X-Auth-Email: ${email}" \
    -H "X-Auth-Key: ${api_key}" \
    -H "Content-Type: application/json" \
    --data '{
        "action": "redirect",
        "expression": "(http.host eq \"'${redirect_domain}'\")",
        "description": "'"${rule_description}"'",
        "action_parameters": {
            "from_value": {
                "status_code": 301,
                "target_url": {
                    "expression": "concat(\"http://'"${ipAddr}"'\", http.request.uri.path)"
                },
                "preserve_query_string": true
            }
        }
    }')

# 输出更新结果
# echo "Update Response: $response"
