#!/bin/bash -xvu

# Todoistから買い物リストを取得してDiscordに投稿する

# 初期設定
tmp=$(mktemp)

work_dir="$(dirname $0)" # スクリプトのあるディレクトリ
filename="$(basename $0)" # スクリプトのファイル名
mkdir -p ${work_dir}/log # ログディレクトリ
#exec 2> ${work_dir}/log/${filename}.$(date +%Y%m%d_%H%M%S) # 標準エラー出力をログファイルに出力
cd ${work_dir}

# 外部の変数ファイルを取得
source ${work_dir}/keys.sh

# Todoistから買い物リストを取得
curl https://api.todoist.com/sync/v9/sync \
    -H "Authorization: Bearer ${TODOIST_TOKEN}" \
    -d sync_token=* \
    -d resource_types='["projects","items"]' |
# 買い物リストprojectのアイテムで、チェックが入っていないものを抽出
jq -r '.items[] | select(.project_id=="'${SHOPPINGLIST_PROJECT_ID}'") | select(.checked==false) | .content' |
# 改行を削除して、一行にまとめる
sed "s/$/\\\n/" |
tr -d "\n" > $tmp-shoppinglist

# Discordに投稿
curl -X POST -H "Content-Type: application/json" -d "{\"content\": \"$(cat $tmp-shoppinglist)\"}" ${DISCORD_WEBHOOK_URL}

# 一時ファイルの削除
rm -f $tmp-*

# 終了
exit 0

