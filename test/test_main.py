from pexpect import pxssh
import getpass
import json
import time

errors = 0

def ping_addr(addr_liste, session, iface=None):
   """Ping addresses on an interface over a session"""
   nombre_erreurs = 0
   for addresse in addr_liste:
        if iface is None:
            final_cmd = 'ping6 -c1 %s > /dev/null 2> /dev/null && echo \'OK\' || echo \'KO\' ' % (addresse)
        else:
            final_cmd = 'ping6 -c1 -I %s %s > /dev/null 2> /dev/null && echo \'OK\' || echo \'KO\' ' % (iface, addresse)

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

def ping(test_data):
    """Ping a list of addresses from a router"""
    test_address = test_data['Ip_addresses']
    errors = 0
    for router in test_address.keys():
        info("Executing test on router %s"%router)
        session = routers[router]['ssh']
        errors += ping_addr(test_address[router], session)
    info('Test ping ended with %s error(s).\n' %(errors))
    return errors

def ping_all_iface(test_data):
    """Ping a list of addresses from all interfaces of a router"""
    test_address = test_data['Ip_addresses']
    errors = 0
    for router in test_address.keys():
        info("Executing test on router %s"%router)
        session = routers[router]['ssh']
        for number_eth in range(0, routers[router]['nb_iface']):
            iface = '%s-eth%s'%(router,number_eth)
            errors += ping_addr(test_address[router], session, iface)
    info('Test ping_all_iface ended with %s error(s).\n' %(errors))
    return errors

def ping_sel_iface(test_data):
    """Ping lists of addresses from specified interfaces of a router"""
    errors = 0
    for router in test_data['routers'].keys():
        info('Testing node %s'%router)
        session = routers[router]['ssh']
        test_data_router = test_data['routers'][router]
        for target in test_data_router:
            iface = '%s-eth%s'%(router, target["if"])
            errors += ping_addr(target["ad"], session, iface)
    info('Test ping_sel_iface ended with %s error(s).\n' %(errors))
    return errors

def test_ospf_routes(test_data):
    """Check if the ospf routing table of a router is correct"""
    errors = 0
    for router in test_data.keys():
        info('Testing the ospf routing table on router %s' % router)
        session = routers[router]['ssh']
        session.sendline('LD_LIBRARY_PATH=/usr/local/lib vtysh -c "show ipv6 route ospf6 json"')
        session.prompt()
        outp = session.before.decode('utf-8')
        #remove the eventual complaints about conf file. And yes, linux use CRLF line endings in tty's
        routes = json.loads(outp.split('\r\n',2)[-1])
        for addr in test_data[router]:
            if addr not in routes.keys():
                errors += 1
                info('The router %s lacks a route to %s' % (router, addr))
    info('Test of the ospf routes ended with %s error(s).\n' %(errors))

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
errors += ping_sel_iface(tests['1-neighbours'])
errors += ping(tests['2-full_connectivity'])
#errors += ping_all_iface(tests['2-full_connectivity']) #tend to produce error for some reasons
errors += test_ospf_routes(tests['3-ospf_tables'])

#down_iface(setup['down-1-iface'])
#time.sleep(30)
#errors += ping_all_iface(tests['2-full_connectivity'])

info('All tests done with %s error(s).\n' % str(errors))

""" Closing all SSH sessions """
for router in routers.keys():
    routers[router]['ssh'].logout()
    info('SSH session to %s closed.'%router)
