from pexpect import pxssh
from io import StringIO
import sys
import getpass
import json
from re import sub

errors = 0

def Send_cmd(iface,addr_liste,cmd,session):
   nombre_erreurs = 0
   for addresse in addr_liste:
        final_cmd = '%s %s %s' % (cmd,iface,addresse)
        session.sendline(final_cmd)
        session.prompt()

        """ Redirect stdout to var in order to parse the json string """
        old_stdout = sys.stdout
        result = StringIO()
        sys.stdout = result
        #print(session.before.decode('utf-8'))
        value = result.getvalue()
        sys.stdout = old_stdout

        """ Clean session returned value in order to parse json """
        v = sub(final_cmd, '', value)
        if 'unreachable' not in v:
            status = 'OK'
            #js = json.loads(v)
            # print(js['report']['hubs'])
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

    if(test_name == '1-neighbours'):
        for router in test_data['routers'].keys():
            info('Testing node %s'%router)
            session = routers[router]['ssh']
            test_data_router = test_data['routers'][router]
            
            for idx, addr_list in enumerate(test_data_router):
                iface = '%s-eth%s'%(router, idx)
                test_errors += Send_cmd(iface,addr_list,cmd,session)
        info('Test %s ended with %s error(s).\n' %(test_name, test_errors))
        errors += test_errors

    if(test_name == "2-full_connectivity"):
        test_address = test_data['Ip_addresses']
        router_number = 1
        while(router_number <= nb_routers):
            router = "R%s"%router_number
            print("\n")
            info("Executing test on router %s"%router)
            session = routers[router]['ssh']
            number_eth = 0
            while(number_eth < nbIfaceEachRouter[router_number-1]):
                iface = '%s-eth%s'%(router,number_eth)
                test_errors += Send_cmd(iface,test_address,cmd,session)
                number_eth += 1
            router_number += 1
        info('Test %s ended with %s error(s).\n' %(test_name, test_errors))
        errors += test_errors

info('All tests done with %s error(s).\n' % str(errors))

""" Closing all SSH sessions """
for router in routers.keys():
    routers[router]['ssh'].logout()
    info('SSH session to %s closed.'%router)
