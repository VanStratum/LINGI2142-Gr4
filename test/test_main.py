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


def execute_command(session, cmd):
    """ Execute command (cmd) on SSH session (session) with given (args) """
    session.sendline(cmd)
    session.prompt()

    """ Redirect stdout to var in order to parse the json string """
    old_stdout = sys.stdout
    result = StringIO()
    sys.stdout = result
    print(session.before.decode('utf-8'))
    value = result.getvalue()
    sys.stdout = old_stdout

    """ Clean session returned value in order to parse json """
    return sub(cmd, '', value)


def router_connectivity_test(session, iface, addr_list):
    errors = 0
    cmd = 'mtr -6 -c1 --json -o D -I %s %s'
    for addr in addr_list:
        v = execute_command(session, cmd % (iface, addr))
        if 'unreachable' not in v:
            status = 'OK'
            #js = json.loads(v)
            # print(js['report']['hubs'])
        else:
            errors += 1
            status = 'ERROR'

        print('%s: %s -> %s'%(status,iface, addr))
    return errors


def link_failure_setup(session, iface, is_down):
    cmd = 'ip link set dev %s down'
    if is_down:
        execute_command(session, cmd % iface)
        # TODO : parse returned value
        info('iface %s down.' % iface)
    return 0


def get_test_fun(test_type):
    if test_type == 'connectivity':
        return router_connectivity_test
    elif test_type == 'link-failure':
        return link_failure_setup
    else:
        return None


def execute_router(router, router_data, test_type):
    session = routers[router]['ssh']
    errors = 0
    for idx, item in enumerate(router_data):
        """ 
        if connectivity, item = list of addresses to reach
        if link-failure, item = 1 if interface to down, 0 otherwise
        """  
        iface = '%s-eth%s'%(router, idx)
        test_fun = get_test_fun(test_type)
        if test_fun is None:
            return None
        errors += test_fun(session, iface, item)
    return errors
        

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

def execute_test(test_name, test_data):
    def on_each_router(data):
        errors = 0
        for router in data['routers'].keys():
            info('Testing node %s'%router)
            session = routers[router]['ssh']
            router_data = data['routers'][router]
            errors += execute_router(router, router_data, test_data['type'])
        return errors

    info("Executing %s test"%test_name)
    test_errors = 0

    if test_data['type'] == 'link-failure':
        for data in test_data['sequences']:
            test_errors += on_each_router(data)
            # TODO : add repair function
            full_co = '2-full_connectivity'
            test_errors = execute_test(full_co, config['tests'][full_co])
            execute_command(session, 'ip link set dev %s up' % iface)
            addr = 'fde4:4:f000::2/127'
            execute_command(session, 'ip addr add dev %s %s' % (iface, addr))
    else:
        test_errors += on_each_router(test_data)

        
    info('Test %s ended with %s error(s).\n' %(test_name, test_errors))
    return test_errors

# TODO : check adress of each router !

tests = config['tests']
errors = 0
for test_name in sorted(tests.keys()):
    """ iterate on all the defined tests """
    test_data = tests[test_name]
    errors += execute_test(test_name, test_data)
    
info('All tests done with %s error(s).\n' % str(errors))

""" Closing all SSH sessions """
for router in routers.keys():
    routers[router]['ssh'].logout()
    info('SSH session to %s closed.'%router)
