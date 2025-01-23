# 设置必要的变量
email="2123146130@qq.com"
api_key="8f46b08f4d030358a3183fa98728be5258cea"
domain="lovelyy.us.kg"  # 主域名信息
rule_description="openwrt"  # 需要更新描述的规则
ipAddr=${ipAddr}  # 动态设置的 IP 地址

# 获取 zone_id（使用缓存）
zone_id=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=${domain}" \
    -H "X-Auth-Email: ${email}" \
    -H "X-Auth-Key: ${api_key}" \
    -H "Content-Type: application/json" | jq -r '.result[0].id')

echo "Zones ID: $zone_id"

# 使用 Zone ID 获取 Rulesets
ruleset_id=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${zone_id}/rulesets" \
    -H "X-Auth-Email: ${email}" \
    -H "X-Auth-Key: ${api_key}" \
    -H "Content-Type: application/json" | \
    jq -r '.result[] | select(.phase == "http_request_dynamic_redirect") | .id')

echo "Ruleset ID: $ruleset_id"

# 获取规则 ID
rule_id=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${zone_id}/rulesets/${ruleset_id}" \
    -H "X-Auth-Email: ${email}" \
    -H "X-Auth-Key: ${api_key}" \
    -H "Content-Type: application/json" | \
    jq -r ".result.rules[] | select(.description == \"${rule_description}\") | .id")

echo "Rule ID: $rule_id"

# 更新规则
response=$(curl -s -X PATCH "https://api.cloudflare.com/client/v4/zones/${zone_id}/rulesets/${ruleset_id}/rules/${rule_id}" \
    -H "X-Auth-Email: ${email}" \
    -H "X-Auth-Key: ${api_key}" \
    -H "Content-Type: application/json" \
    --data '{
        "action": "redirect",
        "expression": "(http.host eq \"op.lovelyy.us.kg\")",
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
echo "Update Response: $response"
