#!/bin/bash
LC_ALL='C'

# 创建临时文件夹
echo "创建临时文件夹"
mkdir -p ./tmp

# 定义规则和允许列表
rules=(
  "https://big.oisd.nl/" # oisd规则
  "https://anti-ad.net/easylist.txt"
  "https://easylist.to/easylist/easylist.txt" # EasyList
  "https://easylist-downloads.adblockplus.org/easylistchina.txt" # Easylistchina
  "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts" # Stevenblack
  "https://raw.githubusercontent.com/TG-Twilight/AWAvenue-Ads-Rule/main/AWAvenue-Ads-Rule.txt" # 秋风
)

allow=(
  "https://raw.githubusercontent.com/liwenjie119/adg-rules/master/white.txt"
  "https://raw.githubusercontent.com/ChengJi-e/AFDNS/master/QD.txt"
)

# 下载规则文件并保存到临时文件夹
echo "下载规则文件..."
for url in "${rules[@]}" "${allow[@]}"; do
  filename=$(basename "$url")
  curl -m 60 --retry-delay 2 --retry 5 -k -L -C - -o "./tmp/$filename" --connect-timeout 60 -s "$url" &
done
wait

# 处理规则文件
echo "处理规则文件..."
cd tmp || exit
cat *.txt | grep -Ev '#|\$|@|!|/|\\|\*' | grep -v -E "^((#.*)|(\s*))$" | grep -v -E "^[0-9f\.:]+\s+(ip6\-)|(localhost|loopback)$" | grep -Ev "local.*\.local.*$" | sed 's/127.0.0.1/0.0.0.0/g' | sed 's/::/0.0.0.0/g' | grep '0.0.0.0' | grep -Ev '.0.0.0.0 ' | sort | uniq >base-src-hosts.txt

# 合并规则并去重
cat base-src-hosts.txt | grep -Ev '#|\$|@|!|/|\\|\*' | grep -v -E "^((#.*)|(\s*))$" | grep -v -E "^[0-9f\.:]+\s+(ip6\-)|(localhost|loopback)$" | sed 's/127.0.0.1 //' | sed 's/0.0.0.0 //' | sed "s/^/||&/g" | sed "s/$/&^/g" | sed '/^$/d' | grep -v '^#' | sort -n | uniq >rules-converted.txt

# 处理允许列表
cat *.txt | sed '/^$/d' | grep -v "#" | sed "s/^/@@||&/g" | sed "s/$/&^/g" | sort -n | uniq >allow-converted.txt

# 将结果复制到主文件夹
cp rules-converted.txt ../rules.txt
cp allow-converted.txt ../allow.txt

echo "规则处理完成"

# 在此处添加后续的处理步骤，如Python脚本处理重复规则和其他操作

echo "更新成功"
exit
