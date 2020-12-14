#!/usr/bin/env bash
API="http://ipv4.icanhazip.com"
DNS="119.29.29.29"
CF_EMAIL=""
CF_APIKEY=""
CF_DOMAIN=""
CF_ZONEID=""
CF_RECORDID=""
CF_TTL="120"

echo=echo
for cmd in echo /bin/echo; do
    $cmd > /dev/null 2>&1 || continue

    if ! $cmd -e "" | grep -qE '^-e'; then
        echo=$cmd
        break
    fi
done

CSI=$($echo -e "\033[")
CEND="${CSI}0m"
CDGREEN="${CSI}32m"
CRED="${CSI}1;31m"
CGREEN="${CSI}1;32m"
CYELLOW="${CSI}1;33m"
CBLUE="${CSI}1;34m"
CMAGENTA="${CSI}1;35m"
CCYAN="${CSI}1;36m"
CSUCCESS="$CDGREEN"
CFAILURE="$CRED"
CQUESTION="$CMAGENTA"
CWARNING="$CYELLOW"
CMSG="$CCYAN"

echo -e "${CYELLOW}[信息] 正在读取当前 IP 地址中！${CEND}"
DYNAMIC_IP=`curl -fsSL $API`
if [[ "$DYNAMIC_IP" == `dig "@$DNS" +short "A" "$CF_DOMAIN" | grep -Ev '^;|\.$' | head -n1` ]]; then
	echo -e "${CYELLOW}[信息] 当前 IP 地址无需更新！${CEND}"
	exit 0
fi

List() {
	echo -e "${CYELLOW}[信息] 正在读取所有 DNS 记录中！${CEND}"

	curl -X GET "https://api.cloudflare.com/client/v4/zones/${CF_ZONEID}/dns_records" \
		-H "X-Auth-Email: ${CF_EMAIL}" \
		-H "X-Auth-Key: ${CF_APIKEY}" \
		-H "Content-Type: application/json"
}

Update() {
	echo -e "${CYELLOW}[信息] 正在更新 DNS 记录中！${CEND}"

	curl -X PUT "https://api.cloudflare.com/client/v4/zones/${CF_ZONEID}/dns_records/${CF_RECORDID}" \
		-H "X-Auth-Email: ${CF_EMAIL}" \
		-H "X-Auth-Key: ${CF_APIKEY}" \
		-H "Content-Type: application/json" \
		--data '{"type": "A", "name": "'${CF_DOMAIN}'", "content": "'${DYNAMIC_IP}'", "ttl": '${CF_TTL}', "proxied": false}'
}

Create() {
	echo -e "${CYELLOW}[信息] 正在创建 DNS 记录中！${CEND}"

	curl -X POST "https://api.cloudflare.com/client/v4/zones/${CF_ZONEID}/dns_records" \
		-H "X-Auth-Email: ${CF_EMAIL}" \
		-H "X-Auth-Key: ${CF_APIKEY}" \
		-H "Content-Type: application/json" \
		--data '{"type": "A", "name": "'${CF_DOMAIN}'", "content": "'${DYNAMIC_IP}'", "ttl": '${CF_TTL}', "proxied": false}'
}

if [[ -z "$1" ]]; then
	Update
elif [[ "$1" == "--create" ]]; then
	Create
elif [[ "$1" == "--list" ]]; then
	List
fi

exit 0
