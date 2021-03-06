import urllib.parse
import urllib.request
import socket
import json
import logging
import time
from subprocess import call
import ifcfg

HEADERS = {'User-Agent': 'Windows/1.4.0 CFNetwork/790.2 Darwin/16.0.0',
           'Connection': 'Keep-Alive',
           'Content-Type': 'application/json; charset=UTF-8',
           'Accept-Encoding': 'gzip, deflate',
           'Accept-Language': 'zh-cn'}


class IfInfo:
    def __init__(self):
        self.dic = ifcfg.interfaces()

    def get_ip(self, interface, logger):
        logger.info('-' * 35)
        logger.info('Initiating %s', interface)
        ip = self.dic[interface]['inet']
        retry = 0
        while ip is None:
            if retry > 5:
                logger.error('ifup %s', interface)
                call(['ifup', interface.replace('macvlan', 'vwan').replace('eth0.2', 'wan')])
                retry = 0
            self.dic = ifcfg.interfaces()
            ip = self.dic[interface]['inet']
            retry += 1
            time.sleep(5)
        logger.info('IP: %s', ip)
        return ip


def get_logger(file):
    logging.basicConfig(filename=file, format='%(asctime)s %(name)-8s %(levelname)-8s %(message)s', level=logging.DEBUG)
    handler = logging.StreamHandler()
    handler.setFormatter(logging.Formatter('%(asctime)s %(name)-8s %(levelname)-8s %(message)s'))
    logger = logging.getLogger()
    logger.addHandler(handler)
    return logger


def login(username, password, ip, logger):
    socket.setdefaulttimeout(10)
    try:
        payload = {'lpsUserName': username,
                   'lpsPwd': password,
                   'wlanuserip': ip,
                   'basip': '61.148.2.182'}
        data = str.encode(urllib.parse.urlencode(payload))
        request = urllib.request.Request('http://114.247.41.52:808/services/portal/portalAuth', data, HEADERS)
        response = urllib.request.urlopen(request).read().decode('UTF-8')
        return json.loads(response)
    except socket.timeout:
        logger.error('Timeout')
