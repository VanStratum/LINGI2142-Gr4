from pexpect import pxssh
from io import StringIO
import sys
import getpass
import json
from re import sub
import time

errors = 0

def Send_cmd(iface,addr_liste,cmd,session):
   nombre_erreurs = 0
   for addresse in addr_liste:
        final_cmd = '%s %s %s > /dev/null 2> /dev/null && echo \'OK\' || echo \'KO\' ' % (cmd,iface,addresse)
        session.sendline(final_cmd)

        session.prompt()
        temp = session.before.decode('utf-8')
        if temp[-4:-2] == 'OK':
            status = 'OK'
        else:
            nombre_erreurs += 1
            status = 'ERROR'
        print('%s: %s -> %s'%(status,iface, addresse))
   return nombre_erreurs

def info(s):
    print('[INFO] %s' % s)


def get_ssh_to(router_port):
    try:
        s = pxssh.pxssh()
        s.login('localhost', username='root', ssh_key='id_rsa', port=router_port, password='passphrase')
        return s
    except pxssh.ExceptionPxssh as e:
        print("pxssh failed on login.")
        print(e)
        return None

def test_full_connectivity(test_data):
    test_address = test_data['Ip_addresses']
    errors = 0
    cmd = 'ping6 -c1 -I'
    for router in routers.keys():
        info("Executing test on router %s"%router)
        session = routers[router]['ssh']
        for number_eth in range(0, routers[router]['nb_iface']-1):
            iface = '%s-eth%s'%(router,number_eth)
            errors += Send_cmd(iface,test_address,cmd,session)
    info('Test 2-full_connectivity ended with %s error(s).\n' %(errors))
    return errors

def test_neighbour(test_data):
    errors = 0
    cmd = 'ping6 -c1 -I'
    for router in test_data['routers'].keys():
        info('Testing node %s'%router)
        session = routers[router]['ssh']
        test_data_router = test_data['routers'][router]
        for idx, addr_list in enumerate(test_data_router):
            iface = '%s-eth%s'%(router, idx)
            errors += Send_cmd(iface,addr_list,cmd,session)
    info('Test 1-neighbours ended with %s error(s).\n' %(errors))
    return errors

def down_iface(data):
    info('Shutting interfaces down')
    for router in data.keys():
        for iface in data[router]:
            session = routers[router]['ssh']
            cmd = 'ip link set ' + iface + ' down'
            session.sendline(cmd)

info('Launching tests')

""" Load tests configuration """
config = None
with open('test/test_cfg.json', 'r') as fp:
    config = json.load(fp)

if config is None:
    print('Cannot load config')
    sys.exit()


""" Open SSH session to each router """
info('Opening SSH sessions on each router.')
nbIfaceEachRouter = []
nb_routers = config['nb_routers']
routers = config['routers']
for router in routers.keys():
    port = routers[router]['port']
    nbIfaceEachRouter.append(routers[router]['nb_iface']) #stock the number of iface for each routeur
    ssh_session = get_ssh_to(port)
    if ssh_session:
        info('SSH session to %s opened.'%router)
    routers[router]['ssh'] = ssh_session

info('Begin testing procedure.\n')


tests = config['tests']
setup = config['setup']
errors = 0
errors += test_neighbour(tests['1-neighbours'])
errors += test_full_connectivity(tests['2-full_connectivity'])
#down_iface(setup['down-1-iface'])
#time.sleep(30)
#errors += test_full_connectivity(tests['2-full_connectivity'])

info('All tests done with %s error(s).\n' % str(errors))

""" Closing all SSH sessions """
for router in routers.keys():
    routers[router]['ssh'].logout()
    info('SSH session to %s closed.'%router)
