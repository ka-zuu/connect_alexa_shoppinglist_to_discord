#!/bin/bash -xvu

# Todoistから買い物リストを取得して、差分をDiscordに投稿する

# 初期設定
tmp=$(mktemp)

work_dir="$(dirname $0)" # スクリプトのあるディレクトリ
filename="$(basename $0)" # スクリプトのファイル名
mkdir -p ${work_dir}/log # ログディレクトリ
exec > ${work_dir}/log/${filename}.$(date +%Y%m%d_%H%M%S) 2>&1 # 標準出力とエラー出力をログファイルに出力
cd ${work_dir}

# 外部の変数ファイルを取得
source ${work_dir}/keys.sh

# Todoistから買い物リストを取得
curl https://api.todoist.com/sync/v9/sync \
    -H "Authorization: Bearer ${TODOIST_TOKEN}" \
    -d sync_token=* \
    -d resource_types='["projects","items"]' |
# 買い物リストprojectのアイテムで、チェックが入っていないものを抽出
jq -r '.items[] | select(.project_id=="'${SHOPPINGLIST_PROJECT_ID}'") | select(.checked==false) | .content' > $tmp-shoppinglist

# 前回の買い物リストとの差分を取得
if [ -s ${work_dir}/shoppinglist_old/shoppinglist.txt ]; then
    diff $tmp-shoppinglist ${work_dir}/shoppinglist_old/shoppinglist.txt |
    # 差分の行だけにする
    grep -e "^>" -e "^<" |
    # 差分を日本語にする
    sed -e "s/^< /追加：/" -e "s/^> /削除：/" |
    # 改行を削除して、一行にまとめる
    sed "s/$/\\\n/" |
    tr -d "\n" > $tmp-shoppinglist-diff
fi

# 差分がある場合は、Discordに投稿
if [ -s $tmp-shoppinglist-diff ]; then
    curl -X POST -H "Content-Type: application/json" \
    -d '{"content": "買うものリストの更新がありました：\n'"$(cat $tmp-shoppinglist-diff)"'"}' ${DISCORD_WEBHOOK_URL}
fi

# 前回の買い物リストファイルを更新
mkdir -p ${work_dir}/shoppinglist_old
cp $tmp-shoppinglist ${work_dir}/shoppinglist_old/shoppinglist.txt

# 一時ファイルの削除
rm -f $tmp-*

# 終了
exit 0
