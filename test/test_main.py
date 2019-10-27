from pexpect import pxssh
from io import StringIO
import sys
import getpass
import json
from re import sub

errors = 0


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
routers = config['routers']
for router in routers.keys():
    port = routers[router]['port']
    ssh_session = get_ssh_to(port)
    if ssh_session:
        info('SSH session to %s opened.'%router)
    routers[router]['ssh'] = ssh_session

info('Begin testing procedure.\n')

tests = config['tests']
for test_name in sorted(tests.keys()):
    test_errors = 0
    info("Executing %s test"%test_name)

    test_data = tests[test_name]
    
    """ Defining which command to send to the router """
    test_type = test_data['type']
    cmd = None
    if test_type == 'connectivity':
        cmd = 'mtr -6 -c1 --json -o D -I'
    
    """ Skip the current test if no recognized cmd """
    if cmd is None:
        continue

    for router in test_data['routers'].keys():
        info('Testing node %s'%router)
        session = routers[router]['ssh']
        test_data_router = test_data['routers'][router]
        
        for idx, addr_list in enumerate(test_data_router):
            iface = '%s-eth%s'%(router, idx)
            for addr in addr_list:
                final_cmd = '%s %s %s' % (cmd,iface,addr)
                session.sendline(final_cmd)
                session.prompt()

                """ Redirect stdout to var in order to parse the json string """
                old_stdout = sys.stdout
                result = StringIO()
                sys.stdout = result
                print(session.before.decode('utf-8'))
                value = result.getvalue()
                sys.stdout = old_stdout

                """ Clean session returned value in order to parse json """
                v = sub(final_cmd, '', value)
                if 'unreachable' not in v:
                    status = 'OK'
                    #js = json.loads(v)
                    # print(js['report']['hubs'])
                else:
                    test_errors += 1
                    status = 'ERROR'

                print('%s: %s -> %s'%(status,iface, addr))
    info('Test %s ended with %s error(s).\n' %(test_name, test_errors))
    errors += test_errors

info('All tests done with %s error(s).\n' % str(errors))

""" Closing all SSH sessions """
for router in routers.keys():
    routers[router]['ssh'].logout()
    info('SSH session to %s closed.'%router)
