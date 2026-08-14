#!/usr/bin/env ucode
'use strict';

import * as fs from 'fs';

const AWG = '/usr/bin/awg';

// AmneziaWG obfuscation parameters: UCI option name -> awg config key.
// Adding a parameter in a future AmneziaWG release is a one-line change here.
const AWG_PARAMS = [
	[ 'awg_jc',   'Jc'   ],
	[ 'awg_jmin', 'Jmin' ],
	[ 'awg_jmax', 'Jmax' ],
	[ 'awg_s1',   'S1'   ],
	[ 'awg_s2',   'S2'   ],
	[ 'awg_s3',   'S3'   ],
	[ 'awg_s4',   'S4'   ],
	[ 'awg_h1',   'H1'   ],
	[ 'awg_h2',   'H2'   ],
	[ 'awg_h3',   'H3'   ],
	[ 'awg_h4',   'H4'   ],
	[ 'awg_i1',   'I1'   ],
	[ 'awg_i2',   'I2'   ],
	[ 'awg_i3',   'I3'   ],
	[ 'awg_i4',   'I4'   ],
	[ 'awg_i5',   'I5'   ],

	// Added in AmneziaWG 3.0.
	[ 'awg_header_protection_key',   'HeaderProtectionKey'   ],
	[ 'awg_content_padding_addition', 'ContentPaddingAddition' ],
	[ 'awg_rekey_after_time',        'RekeyAfterTime'        ],
	[ 'awg_rekey_timeout',           'RekeyTimeout'          ],
	[ 'awg_reject_after_time',       'RejectAfterTime'       ],
	[ 'awg_keepalive_timeout',       'KeepaliveTimeout'      ],
	[ 'awg_max_handshake_attempts',  'MaxHandshakeAttempts'  ],

	// Added in AmneziaWG 3.1.
	[ 'awg_random_trailers',         'RandomTrailers'        ],
	[ 'awg_disable_cookies',         'DisableCookies'        ]
];

function awg_exists() {
	return fs.access(AWG, fs.F_OK);
}

function ensure_module_loaded() {
	if (fs.access('/sys/module/amneziawg', fs.F_OK))
		return true;

	system('modprobe amneziawg >/dev/null 2>&1');

	return fs.access('/sys/module/amneziawg', fs.F_OK);
}

function ensure_key_is_generated(cursor, section_name) {
	let private_key = cursor.get('network', section_name, 'private_key');

	if (!private_key || private_key == 'generate') {
		let proc = fs.popen(`${AWG} genkey`);
		if (!proc)
			return null;

		let generated_key = rtrim(proc.read('all'));
		proc.close();

		if (generated_key) {
			cursor.set('network', section_name, 'private_key', generated_key);
			cursor.commit('network');
			return generated_key;
		}
	}

	return private_key;
}

function to_array(val) {
	return type(val) == 'array' ? val : split(val, /\s+/);
}

function parse_address(addr) {
	if (index(addr, ':') >= 0) {
		if (index(addr, '/') >= 0) {
			let parts = split(addr, '/');
			return { family: 6, address: parts[0], mask: int(parts[1]) };
		}
		return { family: 6, address: addr, mask: 128 };
	}

	if (index(addr, '/') >= 0) {
		let parts = split(addr, '/');
		return { family: 4, address: parts[0], mask: int(parts[1]) };
	}

	return { family: 4, address: addr, mask: 32 };
}

function load_peers(cursor, iface) {
	let peers = [];
	let peer_type = sprintf('amneziawg_%s', iface);

	cursor.foreach('network', peer_type, (peer_section) => {
		let disabled = peer_section.disabled;
		if (disabled == '1')
			return;

		let route_allowed_ips = peer_section.route_allowed_ips;
		let peer_key = peer_section.public_key;
		let peer_eph = peer_section.endpoint_host;
		let peer_port = peer_section.endpoint_port ?? '51820';
		let peer_a_ips = peer_section.allowed_ips;
		let peer_p_ka = peer_section.persistent_keepalive;
		let peer_psk = peer_section.preshared_key;

		if (!peer_key)
			return;

		let peer_data = {
			public_key: peer_key,
			preshared_key: peer_psk,
			endpoint_host: peer_eph,
			endpoint_port: peer_port,
			allowed_ips: peer_a_ips,
			persistent_keepalive: peer_p_ka,
			route_allowed_ips: route_allowed_ips == '1'
		};

		push(peers, peer_data);
	});

	return peers;
}

function proto_setup(proto) {
	if (!awg_exists()) {
		warn('AmneziaWG tools not found at ', AWG, '\n');
		proto.setup_failed();
		return;
	}

	if (!ensure_module_loaded()) {
		warn('AmneziaWG kernel module not available - install kmod-amneziawg\n');
		proto.setup_failed();
		return;
	}

	let iface = proto.iface;
	let config = proto.config;

	system(sprintf('ip link add dev %s type amneziawg 2>/dev/null || true', iface));

	if (config.mtu)
		system(sprintf('ip link set mtu %d dev %s', int(config.mtu), iface));

	let awg_config = '[Interface]\n';
	awg_config += sprintf('PrivateKey=%s\n', config.private_key);

	if (config.listen_port)
		awg_config += sprintf('ListenPort=%d\n', int(config.listen_port));

	if (config.fwmark)
		awg_config += sprintf('FwMark=%s\n', config.fwmark);

	for (let param in AWG_PARAMS) {
		let value = config[param[0]];
		if (value != null && value != '')
			awg_config += sprintf('%s=%s\n', param[1], value);
	}

	let metric = int(config.metric);

	let ipv4_routes = [];
	let ipv6_routes = [];

	for (let peer in config.peers) {
		awg_config += '\n[Peer]\n';
		awg_config += sprintf('PublicKey=%s\n', peer.public_key);

		if (peer.preshared_key)
			awg_config += sprintf('PresharedKey=%s\n', peer.preshared_key);

		if (peer.endpoint_host) {
			let eph = peer.endpoint_host;
			if (index(eph, ':') >= 0 && substr(eph, 0, 1) != '[')
				eph = sprintf('[%s]', eph);
			awg_config += sprintf('Endpoint=%s:%s\n', eph, peer.endpoint_port);
		}

		if (peer.allowed_ips) {
			let allowed_list = to_array(peer.allowed_ips);
			awg_config += sprintf('AllowedIPs=%s\n', join(', ', allowed_list));

			if (peer.route_allowed_ips) {
				for (let allowed_ip in allowed_list) {
					let addr_info = parse_address(allowed_ip);
					let route = { target: addr_info.address, netmask: '' + addr_info.mask };
					if (metric)
						route.metric = metric;
					if (addr_info.family == 6)
						push(ipv6_routes, route);
					else
						push(ipv4_routes, route);
				}
			}
		}

		if (peer.persistent_keepalive)
			awg_config += sprintf('PersistentKeepalive=%s\n', peer.persistent_keepalive);
	}

	let awg_proc = fs.popen(sprintf('%s syncconf %s /dev/stdin', AWG, iface), 'w');
	if (!awg_proc) {
		warn('Failed to run awg syncconf for ', iface, '\n');
		proto.setup_failed();
		return;
	}

	awg_proc.write(awg_config);
	let awg_result = awg_proc.close();

	if (awg_result != 0) {
		warn('awg syncconf failed for ', iface, '\n');
		proto.setup_failed();
		return;
	}

	system(sprintf('ip link set up dev %s', iface));

	let ipv4_addrs = [];
	let ipv6_addrs = [];

	if (config.addresses) {
		let addr_list = to_array(config.addresses);
		for (let address in addr_list) {
			let addr_info = parse_address(address);
			let addr = { ipaddr: addr_info.address, mask: '' + addr_info.mask };
			if (addr_info.family == 6)
				push(ipv6_addrs, addr);
			else
				push(ipv4_addrs, addr);
		}
	}

	let link_data = {
		ifname: iface
	};

	if (length(ipv4_addrs) > 0)
		link_data.ipaddr = ipv4_addrs;

	if (length(ipv6_addrs) > 0)
		link_data.ip6addr = ipv6_addrs;

	if (length(ipv4_routes) > 0)
		link_data.routes = ipv4_routes;

	if (length(ipv6_routes) > 0)
		link_data.routes6 = ipv6_routes;

	if (config.ip6prefix) {
		let prefix_list = to_array(config.ip6prefix);
		if (length(prefix_list) > 0)
			link_data.ip6prefix = prefix_list;
	}

	if (config.nohostroute != '1') {
		let endpoints_proc = fs.popen(sprintf('%s show %s endpoints', AWG, iface));
		if (endpoints_proc) {
			let endpoints_data = endpoints_proc.read('all');
			endpoints_proc.close();

			let endpoint_lines = split(endpoints_data, '\n');
			for (let line in endpoint_lines) {
				if (!line)
					continue;

				let parts = split(rtrim(line), '\t');
				if (length(parts) < 2)
					continue;

				let endpoint = parts[1];
				let addr_match = match(endpoint, regexp('\\[?([0-9.:a-f]+)\\]?:([0-9]+)'));
				if (addr_match && length(addr_match) > 1)
					proto.add_host_dependency(addr_match[1], config.tunlink);
			}
		}
	}

	proto.update_link(true, link_data);
}

function proto_teardown(proto) {
	let iface = proto.iface;
	system(sprintf('ip link del dev %s 2>/dev/null', iface));
	proto.update_link(false);
}

function proto_renew(proto) {
	proto_setup(proto);
}

netifd.add_proto({
	available: true,
	no_proto_task: true,
	'renew-handler': true,
	name: 'amneziawg',

	config: function(ctx) {
		return {
			...ctx.data,
			private_key: ensure_key_is_generated(ctx.uci, ctx.section),
			peers: load_peers(ctx.uci, ctx.section)
		};
	},

	setup: proto_setup,
	teardown: proto_teardown,
	renew: proto_renew
});
