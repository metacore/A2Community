MODULE IPMonitor; (** AUTHOR "Patrick Hunziker"; PURPOSE "simple network sniffer"; *)

IMPORT WSock32, Streams, Commands,IP, Modules, DNS, Network, Strings;

CONST 
	MaxIPPacketSize=64*1024;
	Trace=TRUE;
	Tab=09X;

TYPE 	DatagramHandler*=PROCEDURE{DELEGATE}(interface: ANY; CONST datagram: ARRAY OF CHAR);

TYPE Monitor*= OBJECT
	VAR socket:WSock32.Socket;
		dest: WSock32.sockaddrIn;
		hostname: ARRAY 256 OF CHAR;
		(*local: WSock32.PHostent;*)
		buffer: ARRAY MaxIPPacketSize OF CHAR;
		from: ARRAY 1024 OF CHAR;
		fromLen,res:LONGINT;
		trace, alive:BOOLEAN;
		error:Streams.Writer;
		adr:IP.Adr;
		handlePacket: DatagramHandler;
		
		(* interface=NIL implies currently default interface, but should include all interfaces *)
		PROCEDURE &Init*(interface: IP.Interface; datagramHandler:DatagramHandler; error:Streams.Writer);
		VAR  cmd, nRead, res:LONGINT; 
			str: ARRAY 128 OF CHAR; resStr:ARRAY 0 OF CHAR;
		BEGIN
			handlePacket:=datagramHandler;
			SELF.error:=error;
			trace:=Trace;
			socket:=WSock32.socket(WSock32.AFINet, WSock32.SockRaw, WSock32.IPProtoIP);
			IF (socket#WSock32.InvalidSocket ) THEN 
				(*pool.Add( SELF, SELF.Finalize ) - if multiple monitor objects are used*)
			ELSE
				IF error#NIL THEN error.String("socket=NIL"); error.Ln; error.Update; HALT(200) END;
				RETURN (* to do: handle failure*)
			END;
			
			res:=WSock32.gethostname(hostname, LEN(hostname)); 
			IF trace & (error#NIL) THEN error.String("hostname: "); error.String(hostname); error.Int(res,0); error.Ln; error.Update END;
			
			(*	local := WSock32.gethostbyname(hostname); (*now 'local' will have all local IP addresses from interfaces *)	*)
			(*! to do: implement multiple interfaces, see DNS.Mod*)
			DNS.HostByName(hostname, adr, res);
			IF trace& (error#NIL) THEN IP.AdrToStr(adr,str); error.String("IP: "); error.String(str); error.Ln; error.Update; END;
			
			dest.sinFamily:=WSock32.AFINet;
			dest.sinPort:=0;
			dest.sinAddr:=adr.ipv4Adr;
			WSock32.bind(socket,dest, SIZEOF(WSock32.sockaddrIn));
			
			cmd:=1;
			WSock32.WSAIoctl(socket, WSock32.SIORcvAll, cmd, SIZEOF(LONGINT), resStr, 0, nRead,0, 0); 
			alive:=TRUE;
		END Init;
		
		PROCEDURE Finalize;
		VAR res: LONGINT;
		BEGIN {EXCLUSIVE}
			IF socket # WSock32.InvalidSocket THEN
				res := WSock32.shutdown( socket, WSock32.SDboth );
				res := WSock32.closesocket( socket );
				socket := WSock32.InvalidSocket;
			END;
		END Finalize;
		
		PROCEDURE Die*;
		BEGIN
			Finalize;
			BEGIN{EXCLUSIVE}
				alive:=FALSE
			END;
		END Die;
		
	BEGIN{ACTIVE}
		WHILE alive DO
			fromLen:=1024;
			res:=WSock32.recvfrom(socket,buffer,65536,0,from,fromLen); 
			IF res#WSock32.SocketError THEN 
				handlePacket(NIL,buffer);
			ELSE 
				IF error#NIL THEN error.String("?"); error.Update; END;
			END;
		END;
	END Monitor;

VAR 
	monitor:Monitor;
	log:Streams.Writer;
	
(*default datagram handler*)
PROCEDURE DefaultHandler(interface: ANY; CONST datagram: ARRAY OF CHAR);
VAR src,dst: ARRAY 16 OF CHAR; version, ipHeadLen, protocol, length:LONGINT;
BEGIN
	IF ORD(datagram[0]) DIV 16 # IP.IPv4 THEN HALT(200) END; (*Not yet implemented*)
	protocol:=ORD(datagram[9]);
	CASE protocol OF (*wikipedia: List_of_IP_protocol_numbers*)
		| 1: log.String("ICMP"); log.Char(Tab)
		| 2: log.String("IGMP" );log.Char(Tab) 
		| 6: log.String("TCP "); log.Char(Tab)
		| 17: log.String("UDP "); log.Char(Tab)
	ELSE log.Int(protocol,6); log.Char(Tab)
	END;
	
	version:=ORD(datagram[0]) DIV 16; log.Int(version,4); log.Char(Tab);
	ipHeadLen:= 4 * (ORD(datagram[0]) MOD 16); log.Int(ipHeadLen,4);log.Char(Tab);
	
	length:= Network.GetNet2(datagram, 2); log.Int(length,8); log.Char(Tab);
	
	IpToStr(datagram,12,src);
	IpToStr(datagram,16,dst);
	log.String(src); log.Char(Tab); log.String("=>") ; log.Char(Tab); 
	log.String(dst); log.Char(Tab);
	
	CASE protocol OF (*wikipedia: List_of_IP_protocol_numbers*)
		| 1: (*ICMP);*) log.Int(ORD(datagram[24]),0);
		| 2:(* IGMP); *)
		| 6: (*TCP); *)log.Int(Network.GetNet2(datagram,ipHeadLen),6);log.String("=>");log.Int(Network.GetNet2(datagram,ipHeadLen+2),6); log.Char(Tab); 
						(*window size*) log.Int(Network.GetNet2(datagram,ipHeadLen+14),8); log.Char(Tab);
						(*sequence number*) log.Int(Network.GetNet4(datagram, ipHeadLen+4),12);
		| 17: (*UDP);*) log.Int(Network.GetNet2(datagram,ipHeadLen),6);log.String("=>");log.Int(Network.GetNet2(datagram,ipHeadLen+2),6); log.Char(Tab); 
						(*packet size*) log.Int(Network.GetNet2(datagram,ipHeadLen+4),8);
	ELSE 
	END;
	log.Ln; log.Update;
END DefaultHandler;

PROCEDURE IpToStr(CONST datagram: ARRAY OF CHAR; pos: LONGINT; VAR s: ARRAY OF CHAR);
VAR s0: ARRAY 4 OF CHAR;
BEGIN
	Strings.IntToStr(ORD(datagram[pos]),s); Strings.Append(s,".");
	Strings.IntToStr(ORD(datagram[pos+1]),s0); Strings.Append(s,s0); Strings.Append(s,"."); 
	Strings.IntToStr(ORD(datagram[pos+2]),s0); Strings.Append(s,s0); Strings.Append(s,".");
	Strings.IntToStr(ORD(datagram[pos+3]),s0); Strings.Append(s,s0) 
END IpToStr;


PROCEDURE SrcAdr (CONST datagram: ARRAY OF CHAR): IP.Adr;
VAR adr: IP.Adr;
BEGIN
	CASE ORD(datagram[0]) DIV 16 OF
		IP.IPv4:
			adr.usedProtocol := IP.IPv4;
			adr.ipv4Adr := Network.GetNet4(datagram, 12);
			RETURN adr;
		| IP.IPv6: HALT(200);
	END;
END SrcAdr;

PROCEDURE DstAdr (CONST datagram: ARRAY OF CHAR): IP.Adr;
VAR adr: IP.Adr;
BEGIN
	CASE ORD(datagram[0]) DIV 16 OF
		IP.IPv4:
			adr.usedProtocol := IP.IPv4;
			adr.ipv4Adr := Network.GetNet4(datagram, 16);
			RETURN adr;
		| IP.IPv6: HALT(200);
	END;
END DstAdr;

PROCEDURE Start*(context:Commands.Context);
BEGIN
	NEW(monitor, NIL, DefaultHandler, context.error);
	log:=context.out;
END Start;

PROCEDURE Stop*;
BEGIN
	IF monitor#NIL THEN monitor.Die END;
END Stop;

PROCEDURE Cleanup*;
BEGIN
	IF monitor#NIL THEN 
		monitor.Die;
		BEGIN{EXCLUSIVE} AWAIT(~monitor.alive) END;
		monitor:=NIL;
	END;
END Cleanup;

BEGIN
	Modules.InstallTermHandler(Cleanup)
END IPMonitor.

IPMonitor.Start~
IPMonitor.Stop~  

SystemTools.FreeDownTo WSock32 ~

How to do an IP IpMonitor in Windows using Sockets:
http://www.binarytides.com/packet-IpMonitor-code-in-c-using-winsock/


Packet IPMonitor Code in C using Winsock
Winsock	By Silver Moon On Mar 19, 2007 15 Comments	
Tweet
Winsock packet IpMonitor

A packet IpMonitor is a program that can sniff the packets moving on the network. All applications communicate over the network with data packets where each packet contains part of the whole data being exchanged. A IpMonitor is able to pickup these individual packets and read them.

In this post we are going to write a very simple packet IpMonitor using sockets with the winsock api on windows. Since windows 2000, the winsock api got some features that allowed it to sniff packets moving in and out the network interface.

Ever since windows 2000/XP when IP_HDRINCL became a valid option for setsockopt() , WSAIoctl() had another option called SIO_RCVALL which enabled a raw socket to sniff all incoming traffic over the selected interface to whose IP the socket was bound. Hence to make a IpMonitor in Winsock he simple steps are ...

1. Create a raw socket.
2. Bind the socket to the local IP over which the traffic is to be sniffed.
3. Call WSAIoctl() on the socket with SIO_RCVALL option to give it sniffing powers.
4. Put the socket in an infinite loop of recvfrom.
5. recvfrom gets the packet in the string buffer.

Now this feature of winsock is available on all 2000/XP and higher windows. But there are few drawbacks.

1. Ethernet header is not available in winsock sniffing.
2. Only incoming data is sniffed on XP and XP+SP1.
3. Both incoming and outgoing data is sniffed on XP+SP1+SP2. (actual behavior may vary).

Few more effects might be visible like :

1. Outgoing UDP and ICMP packets are not captured.
2. On Windows Vista with SP1, only UDP packets are captured. TCP packets are not captured at all.

I have not checked higher versions of windows. Moreover non IP packets (e.g. ARP) may not be captured at all.
So if full fledged sniffing is required then packet drivers like winpcap should help.

In the following source code all packets are assumed to be IP packets. VC++ 6.0 on Win XP used here.

Code

First create a raw socket and bind it to a local interface.
1
2
	
SOCKET IpMonitor = socket(AF_INET, SOCK_RAW, IPPROTO_IP);
bind(IpMonitor,(struct sockaddr *)&dest,sizeof(dest))

dest must have the details as follows :
1
2
3
4
5
	
memcpy(&dest.sin_addr.s_addr,local->h_addr_list[in],
sizeof(dest.sin_addr.s_addr));
dest.sin_family = AF_INET;
dest.sin_port = 0;
dest.sin_zero = 0;

where local is a HOSTENT pointer that contains the list of local ip addresses.

Next call WSAIoctl on the socket

1
	
WSAIoctl(IpMonitor, SIO_RCVALL, &j, sizeof(j), 0, 0, &in,0, 0);

where j must be 1 and in can be any integer

Now the final recvfrom loop to sniff data on the socket.
1
2
3
4
	
while(1)
{
 recvfrom(IpMonitor,Buffer,65536,0,0,0); //ring-a-ring-a roses
}

To get the local IPs associated with the machine all that needs to be done is:
1
2
	
gethostname(hostname, sizeof(hostname); //its a char hostname[100] for local hostname
HOSTENT *local = gethostbyname(hostname); //now local will have all local ips

Now socket IpMonitor will receive all incoming packets along with their headers and all that will be stored in the Buffer. To extract various headers from the packet like IP header, tcp header etc, we need some structures.

Here is the code for the ip, tcp, udp and icmp headers
1
2
3
4
5
6
7
8
9
10
11
12
13
14
15
16
17
18
19
20
21
22
23
24
25
26
27
28
29
30
31
32
33
34
35
36
37
38
39
40
41
42
43
44
45
46
47
48
49
50
51
52
53
54
55
56
57
58
59
60
61
62
63
64
65
	
typedef struct ip_hdr
{
 unsigned char  ip_header_len:4;  // 4-bit header length (in 32-bit words)
 unsigned char  ip_version   :4;  // 4-bit IPv4 version
 unsigned char  ip_tos;           // IP type of service
 unsigned short ip_total_length;  // Total length
 unsigned short ip_id;            // Unique identifier
 
 unsigned char  ip_frag_offset   :5; // Fragment offset field
 
 unsigned char  ip_more_fragment :1;
 unsigned char  ip_dont_fragment :1;
 unsigned char  ip_reserved_zero :1;
 
 unsigned char  ip_frag_offset1;    //fragment offset
 
 unsigned char  ip_ttl;           // Time to live
 unsigned char  ip_protocol;      // Protocol(TCP,UDP etc)
 unsigned short ip_checksum;      // IP checksum
 unsigned int   ip_srcaddr;       // Source address
 unsigned int   ip_destaddr;      // Source address
}   IPV4_HDR;
 
typedef struct udp_hdr
{
 unsigned short source_port;     // Source port no.
 unsigned short dest_port;       // Dest. port no.
 unsigned short udp_length;      // Udp packet length
 unsigned short udp_checksum;    // Udp checksum (optional)
}   UDP_HDR;
 
typedef struct tcp_header
{
 unsigned short source_port;  // source port
 unsigned short dest_port;    // destination port
 unsigned int   sequence;     // sequence number - 32 bits
 unsigned int   acknowledge;  // acknowledgement number - 32 bits
 
 unsigned char  ns   :1;          //Nonce Sum Flag Added in RFC 3540.
 unsigned char  reserved_part1:3; //according to rfc
 unsigned char  data_offset:4;    //number of dwords in the TCP header.
 
 unsigned char  fin  :1;      //Finish Flag
 unsigned char  syn  :1;      //Synchronise Flag
 unsigned char  rst  :1;      //Reset Flag
 unsigned char  psh  :1;      //Push Flag
 unsigned char  ack  :1;      //Acknowledgement Flag
 unsigned char  urg  :1;      //Urgent Flag
 
 unsigned char  ecn  :1;      //ECN-Echo Flag
 unsigned char  cwr  :1;      //Congestion Window Reduced Flag
 
 unsigned short window;          // window
 unsigned short checksum;        // checksum
 unsigned short urgent_pointer;  // urgent pointer
}   TCP_HDR;
 
typedef struct icmp_hdr
{
 BYTE type;          // ICMP Error type
 BYTE code;          // Type sub code
 USHORT checksum;
 USHORT id;
 USHORT seq;
}   ICMP_HDR;

The ip_protocol field of the ip header determines the type of the packet. For e.g 1 means a icmp packet and 2-igmp 6-tcp 17-udp and so on.RFC 1340 should help more. Another function in the source code is PrintData() which prints the data dumps in a hex view fashion as done by other IpMonitors and looks like this :


========================================
The SIO_RCVALL control code enables a socket to receive all IPv4 or IPv6 packets passing through a network interface.

To perform this operation, call the WSAIoctl or WSPIoctl function with the following parameters.
C++

int WSAIoctl(
  (socket) s,            // descriptor identifying a socket
  SIO_RCV_ALL,                       // dwIoControlCode
  NULL,                              // lpvInBuffer
  0,                                 // cbInBuffer
  NULL,                              // lpvOutBuffer output buffer
  (DWORD) cbOutBuffer,            // size of output buffer  
  (LPDWORD) lpcbBytesReturned,    // number of bytes returned
  (LPWSAOVERLAPPED) lpOverlapped, // OVERLAPPED structure
  (LPWSAOVERLAPPED_COMPLETION_ROUTINE) lpCompletionRoutine,  // completion routine
);

see https://msdn.microsoft.com/en-us/library/windows/desktop/ee309610%28v=vs.85%29.aspx
===================================
/*------------------------------from http://cdcontent.books24x7.com/id_13466/IpMonitor.c----------------------------------------------
 *
 *						A simple IpMonitor for W2K/NT
 *						=============================
 *
 * This simple IpMonitor grabs all IP packets incming from one interface. 
 * The IpMonitor requires administrative privileges.
 *
 * General idea
 * ----------------
 * Having gained control, the shellcode switches the system into
 * promiscuous mode and grabs all traffic that passes through the host, some
 * way or other separating its own packets from foreign packets. For example,
 * this might be done by a unique signature, by sender address of port number,
 * or using any other method.
 *
 * Implementation
 * ---------------
 * socket(SOCK_RAW) -> WSAIoctl(SIO_ADDRESS_LIST_QUERY) -> bind -> ...
 * -> WSAIoctl(SIO_RCVALL) -> recv(). This approach works only under w2k or higher,
 * and only provided that the attacker has administrative privileges.
 * Attention: This implementation for similicity grabs packets
 * incoming only from one interface (including PPP connection).
 * 	
 * Possible problems
 * ------------------
 * This exploit does not work under Windows 9x, Windows NT, and 
 * under UNIX (where packets are grabbed differently, specific way under each system). 
 * Also, the fact of grabbing can be disclosed using special intrusion detection
 * tools. Therefore, it is not recommended to continuously use the interface in
 * order to prevent being disclosed.
 *		
 * Demonstration
 * -------------
 * > Attacked: IpMonitor.exe, if desired, it is possible to check mail or visit some www address
 * > Attacker: sends packets to any port allowed by the firewall.
 *	
----------------------------------------------------------------------------*/
#include <stdio.h>
#include <winsock2.h>
#include <ws2tcpip.h>
#include <windows.h>

main()
{

	int n_addr;
	int N, a, i;
	int addrcount;

	int len;
	int optval = 1;

	SOCKET raw_socket;
	struct sockaddr_in addr;    
	unsigned char buf[10000];
	unsigned char addrlist[1024];
    SOCKET_ADDRESS_LIST *llist;

    llist = (SOCKET_ADDRESS_LIST*) addrlist;

	// TITLE
	 printf("IpMonitor exploit demo");
  
    // Library initialization
    //------------------------------------------------------------------------
	if (WSAStartup(0x202, (struct WSAData*) buf) != 0 ) {
		printf("-ERR:WSAStartup() -> %d\n", WSAGetLastError());return -1;
	}

	// Create a raw socket
	//------------------------------------------------------------------------
	if ( (raw_socket = socket(AF_INET, SOCK_RAW, IPPROTO_IP)) == INVALID_SOCKET) {
		printf("-ERR:socket(,SOCK_RAW,) -> %d\n", WSAGetLastError());return -1;
	}

	// Some manuals state that raw socket must be assigned the IP_HDRINCL attribute.
	// Naturally, it is possible to assign this attribute, however, it is not necessar!
	// The IP_HDRINCL flag informs the system that the application will on its own
	// form the IP header of the packets being sent, and received packets are
        // supplied to it along with the header in any case. 
	// See PlatformSDK/TCP/IP Raw Sockets for more details
	// if (setsockopt(raw_socket, IPPROTO_IP, IP_HDRINCL, (char*)&optval, sizeof(optval)) == SOCKET_ERROR)	{
	//	printf("-ERR:setsockopt(,,IP_HDRINCL) -> %d\n", WSAGetLastError()); return -1;
	//}

	// Enumerate all interfaces (in other words, addresses of all IP interfaces of all gateways
	// that are present on the computer). In case of a ppp connection, 
        // usually there is only one IP address assigned by the ISP's DHCP server, however,
	// this is not so within a local area network.
	if (WSAIoctl(raw_socket, SIO_ADDRESS_LIST_QUERY, 0, 0, addrlist, sizeof(addrlist), &N, 0, 0) == SOCKET_ERROR){
		printf("-ERR:WSAIoctl(,SIO_ADDRESS_LIST_QUERY) error %d\n", WSAGetLastError()); return -1;
	}

	if ((n_addr = llist->iAddressCount) == 0) {
		printf("-ERR:IP list is empty\n");return -1;
	}

	// Print the list of available interfaces
	for(a = 0; a < n_addr; a++)
		printf("IP - %s\n", inet_ntoa(((struct sockaddr_in*) llist->Address[a].lpSockaddr)->sin_addr));

	// Now it is necessary to bind to all interfaces, allocate an individual thread
	// to each (sockets are blockable). However, in this demo example, only the first
        // IP out of all is listened
	addr.sin_family = AF_INET;
	addr.sin_addr   = ((struct sockaddr_in*) llist->Address[0].lpSockaddr)->sin_addr;
    
    //addr.sin_addr.s_addr	 = inet_addr("192.168.16.17");
	if (bind(raw_socket, (struct sockaddr*) &addr, sizeof(addr)) == SOCKET_ERROR) {
		printf("-ERR:bind\n"); return -1;
	}

	#define SIO_RCVALL  0x98000001

	// Inform the system that it is necessary to receive all packets passing through it
	if (WSAIoctl(raw_socket, SIO_RCVALL, &optval, sizeof(optval), 0,0,&N,0,0) == SOCKET_ERROR){
    	printf("-ERR:WSAIoctl(SIO_RCVALL) -> %d\n", WSAGetLastError()); return -1;
	}

	// Get all packets arriving to the given interface
	// and print their contents
	while(1)
	{
	    if ((len = recv(raw_socket, buf, sizeof(buf), 0)) < 1) {
			printf("-ERR:recv() -> %d, WSAGetLastError=%i\n", len,WSAGetLastError()); return -1;
		}

		// Print the packet contents in hex format
		for (i = 0; i < len; i += 16)
		{
			for (a = 0; a < ( ((len - i)>16)?16:(len-i)); a++)				
				printf("%02X ", buf[i+a]);

			if ((len - i)<16) for (a = 0; a < 16 - (len % 16); a++) printf("   ");
			for (a = 0; a < ( ((len - i)>16)?16:(len-i)); a++)
				printf("%c", (buf[i+a]>=0x20)?buf[i+a]:'.');
				  printf("\n");
		}
		printf("----------------------------------------------------------------\n");

	}
}
