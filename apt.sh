echo "-- 更新 apt 源"
sed -i 's|http://archive.ubuntu.com|https://mirror.nju.edu.cn|g' /etc/apt/sources.list
apt update -y && apt upgrade -y
apt install -y zsh unzip language-pack-zh-hans htop