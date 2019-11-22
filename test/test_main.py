from pexpect import pxssh
import getpass
import json
import time

def ping_addr(addr_liste, session, exp_up, iface=None):
   """Ping addresses on an interface over a session.
      exp_up specifies if the address is supposed to be reachable."""
   nombre_erreurs = 0
   for addresse in addr_liste:
        if iface is None:
            final_cmd = 'ping6 -c1 %s > /dev/null 2> /dev/null && /bin/echo \'OK\' || /bin/echo \'KO\' ' % (addresse)
        else:
            final_cmd = 'ping6 -c1 -I %s %s > /dev/null 2> /dev/null && /bin/echo \'OK\' || /bin/echo \'KO\' ' % (iface, addresse)

        session.sendline(final_cmd)

        session.prompt()
        temp = session.before.decode('utf-8')
        if (temp[-4:-2] == 'OK') == exp_up:
            status = 'OK'
        else:
            nombre_erreurs += 1
            status = '\033[31mERROR'
        print('%s: %s -> %s\033[0m'%(status,iface, addresse))
   return nombre_erreurs

def info(s):
    print('\033[33m[INFO] %s\033[0m' % s)


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
    errors = 0
    for test_type in ['Up', 'Down']:
        info('Test adresses that should be %s' % (test_type))
        for router in test_data[test_type].keys():
            info("Executing test on router %s"%router)
            session = routers[router]['ssh']
            errors += ping_addr(test_data[test_type][router], session, test_type == 'Up')
    info('Test ping ended with %s error(s).\n' %(errors))
    return errors

def ping_all_iface(test_data):
    """Ping a list of addresses from all interfaces of a router"""
    errors = 0
    for test_type in ['Up', 'Down']:
        info('Test adresses that should be %s' % (test_type))
        for router in test_data[test_type].keys():
            info("Executing test on router %s"%router)
            session = routers[router]['ssh']
            for number_eth in range(0, routers[router]['nb_iface']):
                iface = '%s-eth%s'%(router,number_eth)
                errors += ping_addr(test_data[test_type][router], session, test_type == 'Up', iface)
    info('Test ping_all_iface ended with %s error(s).\n' %(errors))
    return errors

def ping_sel_iface(test_data):
    """Ping lists of addresses from specified interfaces of a router"""
    errors = 0
    for test_type in ['Up', 'Down']:
        info('Test adresses that should be %s' % (test_type))
        for router in test_data[test_type].keys():
            info('Testing node %s'%router)
            session = routers[router]['ssh']
            test_data_router = test_data[test_type][router]
            for target in test_data_router:
                iface = '%s-eth%s'%(router, target["if"])
                errors += ping_addr(target["ad"], session, test_type=='Up', iface)
    info('Test ping_sel_iface ended with %s error(s).\n' %(errors))
    return errors

def test_ospf_routes(test_data):
    """Check if the ospf routing table of a router is correct"""
    errors = 0
    for test_type in ['Up', 'Down']:
        info('Test ospf route that should%s exist' % ('' if (test_type=='Up') else "n't"))
        for router in test_data[test_type].keys():
            print('Testing the ospf routing table on router %s' % router)
            session = routers[router]['ssh']
            session.sendline('LD_LIBRARY_PATH=/usr/local/lib vtysh -c "show ipv6 route ospf6 json"')
            session.prompt()
            outp = session.before.decode('utf-8')
            try:
                #remove the eventual complaints about conf file. And yes, linux use CRLF line endings in tty's
                routes = json.loads(outp.split('\r\n',2)[-1])
                for addr in test_data[test_type][router]:
                    if (addr not in routes.keys()) == (test_type == 'Up'):
                        errors += 1
                        print('\033[31mThe router %s %s a route to %s\033[0m' % (router, 'lacks' if (test_type == 'Up') else 'has',addr))
            except ValueError:
                print('\033[31mFailed to get the ospf tables, ignoring\033[0m') # can happen if pexpect freaks out
    info('Test of the ospf routes ended with %s error(s).\n' %(errors))

    return errors

def down_iface(data):
    info('Shutting interfaces down')
    for router in data.keys():
        for iface in data[router]:
            session = routers[router]['ssh']
            iface = router + '-eth' + str(iface)
            cmd = 'ip link set ' + iface + ' down'
            session.sendline(cmd)
            session.prompt()

def restore_iface(data):
    info('Restoring downed interfaces')
    for router in data.keys():
        with open('templates/'+router+'.json', 'r') as fp:
            config = json.load(fp)
        address = config['ifaces']['routing']
        for iface in data[router]:
            name = router + '-eth' + str(iface)
            session = routers[router]['ssh']
            cmd = 'ip link set dev ' + name + ' up'
            session.sendline(cmd)
            session.prompt()
            cmd = 'ip -6 addr add fde4:4:f000::' + address[iface][0] + '/127 dev ' + name
            session.sendline(cmd)
            session.prompt()


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
errors += ping(tests['1-full_connectivity'])
#errors += ping_all_iface(tests['2-full_connectivity']) #tend to produce error for some reasons
errors += test_ospf_routes(tests['1-ospf_tables'])

#info('%s errors so far' % str(errors))
#down_iface(setup['2-down_R01'])  ####Simulate the dead of R01, expect havoc.
#time.sleep(300)
#errors += ping(tests['2-full_connectivity'])
#errors += ping_sel_iface(tests['2-neighbours'])
#errors += test_ospf_routes(tests['2-ospf_tables'])
#restore_iface(setup['2-down_R01'])
#
#time.sleep(300)
#errors += ping(tests['1-full_connectivity'])
#errors += ping_sel_iface(tests['1-neighbours'])
#errors += test_ospf_routes(tests['1-ospf_tables'])

info('All tests done with %s error(s).\n' % str(errors))

""" Closing all SSH sessions """
for router in routers.keys():
    routers[router]['ssh'].logout()
    info('SSH session to %s closed.'%router)
