#!/bin/sh

# 需要的依赖 Base64

# 配置变量
ACCESS_TOKEN="你的码云API"
REPO_OWNER="你的码云名称"
REPO_NAME="你的码云项目"
FILE_PATH="你的码云需要变更的文件"

# 动态获取公网地址并拼接端口
# NEW_CONTENT="$(curl -s -4 ip.sb):65535"
# NEW_CONTENT="${ipAddr}"
NEW_CONTENT="[ { \"protocol\" : \"http\" , \"host\" : \"${ipAddr}\" , \"filesuffix\": [ \"php\" ] }]"

# 检查 NEW_CONTENT 是否为空
if [ -z "$NEW_CONTENT" ]; then
  echo "无法获取公网地址，请检查网络连接。"
  exit 1
fi

# 获取文件的 SHA 值
SHA=$(curl -s -H "Authorization: token $ACCESS_TOKEN" \
"https://gitee.com/api/v5/repos/$REPO_OWNER/$REPO_NAME/contents/$FILE_PATH" | jq -r '.sha')

# 检查 SHA 值是否获取成功
if [ -z "$SHA" ]; then
  echo "无法获取文件的 SHA 值，请检查文件路径或仓库权限。"
  exit 1
fi

# 将新内容编码为 Base64
ENCODED_CONTENT=$(echo -n "$NEW_CONTENT" | base64)

# echo $ENCODED_CONTENT

# 更新文件内容
RESPONSE=$(curl -s -X PUT -H "Authorization: token $ACCESS_TOKEN" \
-H "Content-Type: application/json" \
-d "$(cat <<EOF
{
  "message": "Lucky shell热更新",
  "content": "$ENCODED_CONTENT",
  "sha": "$SHA"
}
EOF
)" \
"https://gitee.com/api/v5/repos/$REPO_OWNER/$REPO_NAME/contents/$FILE_PATH")

# 检查响应结果
if echo "$RESPONSE" | grep -q '"content"'; then
  echo "公网地址已成功更新为: $NEW_CONTENT"
else
  echo "更新失败: $RESPONSE"
fi
