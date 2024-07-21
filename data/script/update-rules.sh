#!/bin/sh
#!/bin/bash
LC_ALL='C'

rm *.txt
# 创建临时文件夹
echo "创建临时文件夹"
mkdir -p ./tmp

wait
echo '创建临时文件夹'
mkdir -p ./tmp/

#添加补充规则
cp ./data/rules/adblock.txt ./tmp/rules01.txt
cp ./data/rules/whitelist.txt ./tmp/allow01.txt

cd tmp


echo '下载规则'
# 定义规则和允许列表
rules=(
  "https://big.oisd.nl/" #oisd规则
  "https://big.oisd.nl/" # oisd规则
  "https://anti-ad.net/easylist.txt"
  "https://easylist.to/easylist/easylist.txt" #EasyList
  "https://easylist-downloads.adblockplus.org/easylistchina.txt" #Easylistchina
  "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts" #Stevenblack
  "https://raw.githubusercontent.com/TG-Twilight/AWAvenue-Ads-Rule/main/AWAvenue-Ads-Rule.txt" #秋风
 )
  "https://easylist.to/easylist/easylist.txt" # EasyList
  "https://easylist-downloads.adblockplus.org/easylistchina.txt" # Easylistchina
  "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts" # Stevenblack
  "https://raw.githubusercontent.com/TG-Twilight/AWAvenue-Ads-Rule/main/AWAvenue-Ads-Rule.txt" # 秋风
)

allow=(
  "https://raw.githubusercontent.com/liwenjie119/adg-rules/master/white.txt"
  "https://raw.githubusercontent.com/ChengJi-e/AFDNS/master/QD.txt"
)

for i in "${!rules[@]}" "${!allow[@]}"
do
  curl -m 60 --retry-delay 2 --retry 5 --parallel --parallel-immediate -k -L -C - -o "rules${i}.txt" --connect-timeout 60 -s "${rules[$i]}" |iconv -t utf-8 &
  curl -m 60 --retry-delay 2 --retry 5 --parallel --parallel-immediate -k -L -C - -o "allow${i}.txt" --connect-timeout 60 -s "${allow[$i]}" |iconv -t utf-8 &
done
wait
echo '规则下载完成'

# 添加空格
file="$(ls|sort -u)"
for i in $file; do
  echo -e '\n' >> $i &
# 下载规则文件并保存到临时文件夹
echo "下载规则文件..."
for url in "${rules[@]}" "${allow[@]}"; do
  filename=$(basename "$url")
  curl -m 60 --retry-delay 2 --retry 5 -k -L -C - -o "./tmp/$filename" --connect-timeout 60 -s "$url" &
done
wait

echo '处理规则中'

cat | sort -n| grep -v -E "^((#.*)|(\s*))$" \
 | grep -v -E "^[0-9f\.:]+\s+(ip6\-)|(localhost|local|loopback)$" \
 | grep -Ev "local.*\.local.*$" \
 | sed s/127.0.0.1/0.0.0.0/g | sed s/::/0.0.0.0/g |grep '0.0.0.0' |grep -Ev '.0.0.0.0 ' | sort \
 |uniq >base-src-hosts.txt &
wait
cat base-src-hosts.txt | grep -Ev '#|\$|@|!|/|\\|\*'\
 | grep -v -E "^((#.*)|(\s*))$" \
 | grep -v -E "^[0-9f\.:]+\s+(ip6\-)|(localhost|loopback)$" \
 | sed 's/127.0.0.1 //' | sed 's/0.0.0.0 //' \
 | sed "s/^/||&/g" |sed "s/$/&^/g"| sed '/^$/d' \
 | grep -v '^#' \
 | sort -n | uniq | awk '!a[$0]++' \
 | grep -E "^((\|\|)\S+\^)" & #Hosts规则转ABP规则

cat | sed '/^$/d' | grep -v '#' \
 | sed "s/^/@@||&/g" | sed "s/$/&^/g"  \
 | sort -n | uniq | awk '!a[$0]++' & #将允许域名转换为ABP规则

cat | sed '/^$/d' | grep -v "#" \
 |sed "s/^/@@||&/g" | sed "s/$/&^/g" | sort -n \
 | uniq | awk '!a[$0]++' & #将允许域名转换为ABP规则

cat | sed '/^$/d' | grep -v "#" \
 |sed "s/^/0.0.0.0 &/g" | sort -n \
 | uniq | awk '!a[$0]++' & #将允许域名转换为ABP规则
# 处理规则文件
echo "处理规则文件..."
cd tmp || exit
cat *.txt | grep -Ev '#|\$|@|!|/|\\|\*' | grep -v -E "^((#.*)|(\s*))$" | grep -v -E "^[0-9f\.:]+\s+(ip6\-)|(localhost|loopback)$" | grep -Ev "local.*\.local.*$" | sed 's/127.0.0.1/0.0.0.0/g' | sed 's/::/0.0.0.0/g' | grep '0.0.0.0' | grep -Ev '.0.0.0.0 ' | sort | uniq >base-src-hosts.txt

cat *.txt | sed '/^$/d' \
 |grep -E "^\/[a-z]([a-z]|\.)*\.$" \
 |sort -u > l.txt &
# 合并规则并去重
cat base-src-hosts.txt | grep -Ev '#|\$|@|!|/|\\|\*' | grep -v -E "^((#.*)|(\s*))$" | grep -v -E "^[0-9f\.:]+\s+(ip6\-)|(localhost|loopback)$" | sed 's/127.0.0.1 //' | sed 's/0.0.0.0 //' | sed "s/^/||&/g" | sed "s/$/&^/g" | sed '/^$/d' | grep -v '^#' | sort -n | uniq >rules-converted.txt

cat \
 | sed "s/^/||&/g" | sed "s/$/&^/g" &
# 处理允许列表
cat *.txt | sed '/^$/d' | grep -v "#" | sed "s/^/@@||&/g" | sed "s/$/&^/g" | sort -n | uniq >allow-converted.txt

cat \
 | sed "s/^/0.0.0.0 &/g" &
# 将结果复制到主文件夹
cp rules-converted.txt ../rules.txt
cp allow-converted.txt ../allow.txt

echo "规则处理完成"

echo 开始合并

cat rules*.txt \
 |grep -Ev "^((\!)|(\[)).*" \
 | sort -n | uniq | awk '!a[$0]++' > tmp-rules.txt & #处理AdGuard的规则

cat \
 | grep -E "^[(\@\@)|(\|\|)][^\/\^]+\^$" \
 | grep -Ev "([0-9]{1,3}.){3}[0-9]{1,3}" \
 | sort | uniq > ll.txt &
wait


cat *.txt | grep '^@' \
 | sort -n | uniq > tmp-allow.txt & #允许清单处理
wait

cp tmp-allow.txt .././allow.txt
cp tmp-rules.txt .././rules.txt

echo 规则合并完成

# Python 处理重复规则
python .././data/python/rule.py
python .././data/python/filter-dns.py

# Start Add title and date
python .././data/python/title.py


wait
echo '更新成功'
# 在此处添加后续的处理步骤，如Python脚本处理重复规则和其他操作

echo "更新成功"
exit
