#!/bin/sh
USERNAME="23333333"
PASSWORD="23333333"
LOGFILE=/tmp/culogin.log
UA="Mozilla/5.0 (iPad; CPU OS 9_1 like Mac OS X) AppleWebKit/600.1.4 (KHTML, like Gecko) Version/7.0 Mobile/13B5110e Safari/600.1.4"

login() {
RESPONSE=`curl "http://114.247.41.52:808/protalAction!portalAuth.action?" -H "Cookie: $COOKIE" -H "Origin: http://114.247.41.52:808" -H "Accept-Encoding: gzip, deflate" -H "Accept-Language: zh-CN,zh;q=0.8" -H "User-Agent: $UA" -H "Content-Type: application/x-www-form-urlencoded" -H "Accept: application/json, text/javascript, */*" -H "Referer: http://114.247.41.52:808/protalAction!index.action?wlanuserip=$WLANUSERIP&basip=61.148.2.182" -H "X-Requested-With: XMLHttpRequest" -H "Connection: keep-alive" --data "wlanuserip=$WLANUSERIP&localIp=&basip=61.148.2.182&lpsUserName=$USERNAME&lpsPwd=$PASSWORD" -s`
echo `date +'%Y-%m-%d %H:%M:%S'` $RESPONSE >> $LOGFILE
STATUS=`echo $RESPONSE | grep -E "parsererror|No result defined"`
}


echo `date +'%Y-%m-%d %H:%M:%S'` "Starting...">> $LOGFILE
WLANUSERIP=`ifconfig | grep -oE "172\.16\.[0-9]{1,3}\.[0-9]{1,3}" | awk 'NR==1'`
until [ $WLANUSERIP ]
do
	sleep 3
	echo `date +'%Y-%m-%d %H:%M:%S'` "Retry for WAN IP." >> $LOGFILE
	WLANUSERIP=`ifconfig | grep -oE "172\.16\.[0-9]{1,3}\.[0-9]{1,3}" | awk 'NR==1'`
done
echo `date +'%Y-%m-%d %H:%M:%S'` "User IP:" $WLANUSERIP >> $LOGFILE
COOKIE=`curl 114.247.41.52:808 -I -s --retry 100 | grep "Set-Cookie" | cut -c13-55`
login
while [ "$STATUS" ]
do 
	login
done
echo `date +'%Y-%m-%d %H:%M:%S'` "Done." >> $LOGFILE
