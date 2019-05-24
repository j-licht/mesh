import inet.node.inet.AdhocHost;

import inet.networklayer.configurator.ipv4.Ipv4NetworkConfigurator;
import inet.node.inet.INetworkNode;
import inet.physicallayer.contract.packetlevel.IRadioMedium;
import inet.visualizer.contract.IIntegratedVisualizer;
import inet.emulation.networklayer.ipv4.ExtUpperIpv4NetworkLayer;
import inet.node.base.LinkLayerNodeBase;
import inet.common.MessageDispatcher;

import inet.common.MessageDispatcher;
import inet.common.lifecycle.NodeStatus;
import inet.linklayer.contract.IExternalInterface;
import inet.linklayer.contract.IMacAddressTable;
import inet.linklayer.contract.IMacRelayUnit;
import inet.linklayer.contract.IWirelessInterface;
import inet.mobility.contract.IMobility;
import inet.networklayer.common.InterfaceTable;


module ASwitch
{
    parameters:
        @networkNode();
        @labels(node,ethernet-node,wireless-node);
        @display("i=device/cellphone");
        int numWlanInterfaces = default(1);               // the number of radios in the access point
        int numExtInterfaces = default(1);
        bool hasStatus = default(false);
        wlan[*].mgmt.typename = default("Ieee80211MgmtAdhoc");
        wlan[*].llc.typename = default("Ieee80211Portal");
        wlan[*].agent.typename = default("");
        wlan[*].radio.antenna.mobilityModule = default("^.^.^.mobility");
        //eth[*].encap.typename = "EtherEncapDummy";
        ext[*].encap.typename = "EtherEncapDummy";
        //ext[*].rawSocket.protocol = default("ethernetMac");
	ext[*].copyConfiguration = "copyFromExt";
        *.interfaceTableModule = default(absPath(".interfaceTable"));
        relayUnit.hasStp = false;
    gates:
        input radioIn[numWlanInterfaces] @directIn;
        //inout ethg[] @labels(EtherFrame-conn);
    submodules:
        status: NodeStatus if hasStatus {
            parameters:
                @display("p=100,100;is=s");
        }
	//encap: <default("EtherEncap")> like IEtherEncap {
       //     parameters:
        //        @display("p=100,100");
        //}

        interfaceTable: InterfaceTable {
            parameters:
                @display("p=100,200;is=s");
        }
        mobility: <default("StationaryMobility")> like IMobility {
            parameters:
                @display("p=100,400;is=s");
        }
        macTable: <default("MacAddressTable")> like IMacAddressTable {
            parameters:
                @display("p=100,300;is=s");
        }
        relayUnit: <default(firstAvailable("Ieee8021dRelay","MacRelayUnit"))> like IMacRelayUnit {
            parameters:
                @display("p=400,100");
        }
        nl: MessageDispatcher {
            parameters:
                @display("p=800,200;b=1200,5,,,,1");
        }
        wlan[numWlanInterfaces]: <default("Ieee80211Interface")> like IWirelessInterface {
            parameters:
                @display("p=250,300,row,150;q=queue");
        }
        ext[numExtInterfaces]: <default("ExtLowerEthernetInterface")> like IExternalInterface {
            parameters:
                @display("p=1125,616,row,150;q=txQueue");
		//csmacdSupport = true;
        }
    connections allowunconnected:
        nl.out++ --> relayUnit.ifIn; //if sizeof(ethg)+numWlanInterfaces > 1 && exists(relayUnit);
        nl.in++ <-- relayUnit.ifOut; //if sizeof(ethg)+numWlanInterfaces > 1 && exists(relayUnit);
        // connections to network outside
        // wireless interfaces MUST be connected first (i.e. ports 0..numWlanInterfaces-1)
        // because broadcasts must be handled differently for wireless IFs by the relayUnit
        for i=0..numWlanInterfaces-1 {
            radioIn[i] --> { @display("m=s"); } --> wlan[i].radioIn;
            wlan[i].upperLayerOut --> nl.in++; //if sizeof(ethg)+numWlanInterfaces > 1 && exists(relayUnit);
            wlan[i].upperLayerIn <-- nl.out++; //if sizeof(ethg)+numWlanInterfaces > 1 && exists(relayUnit);
        }
        // ethernet must be connected only AFTER wireless ports
        for i=0..numExtInterfaces-1 {
            ext[i].upperLayerOut --> nl.in++;
            ext[i].upperLayerIn <-- nl.out++;
        }
}

module TestHost extends LinkLayerNodeBase
{
    parameters:
	numWlanInterfaces = 1;
	wlan[*].mgmt.typename = default("Ieee80211MgmtAdhoc");
        wlan[*].agent.typename = default("");
    submodules:
        ipv4: ExtUpperIpv4NetworkLayer {}
	nl: MessageDispatcher {
            parameters:
                @display("p=750,446;b=1000,5,,,,1");
        }
    connections allowunconnected:
        ipv4.ifIn <-- nl.out++;
        ipv4.ifOut --> nl.in++;

        for i=0..numLoInterfaces-1 {
            nl.out++ --> lo[i].upperLayerIn;
            lo[i].upperLayerOut --> nl.in++;
        }

        for i=0..sizeof(radioIn)-1 {
            wlan[i].upperLayerOut --> nl.in++;
            wlan[i].upperLayerIn <-- nl.out++;
        }

        for i=0..sizeof(ethg)-1 {
            eth[i].upperLayerOut --> nl.in++;
            eth[i].upperLayerIn <-- nl.out++;
        }

        for i=0..sizeof(pppg)-1 {
            ppp[i].upperLayerOut --> nl.in++;
            ppp[i].upperLayerIn <-- nl.out++;
        }

        for i=0..numExtInterfaces-1 {
            ext[i].upperLayerOut --> nl.in++;
            ext[i].upperLayerIn <-- nl.out++;
        }

        for i=0..numTunInterfaces-1 {
            tun[i].upperLayerOut --> nl.in++;
            tun[i].upperLayerIn <-- nl.out++;
        }

        for i=0..numVlanInterfaces-1 {
            vlan[i].upperLayerOut --> nl.in++;
            vlan[i].upperLayerIn <-- nl.out++;
        }
}

network TestNetwork
{
    parameters:
        double testTimeout @unit(s) = default(0s);
        bool testing = default(false);
    //parameters:
    //    @display("bgb=650,500;bgg=100,1,grey95");
     //   @figure[title](type=label; pos=0,-1; anchor=sw; color=darkblue);

//        @figure[rcvdPkText](type=indicatorText; pos=380,20; anchor=w; font=,18; textFormat="packets received: %g"; initialValue=0);
 //       @statistic[packetReceived](source=hostB.app[0].packetReceived; record=figure(count); targetFigure=rcvdPkText);*/

    submodules:
        //visualizer: <default("IntegratedCanvasVisualizer")> like IIntegratedVisualizer if hasVisualizer() {
        //    @display("p=580,125");
       // }
        configurator: Ipv4NetworkConfigurator {
            @display("p=580,200");
        }
        radioMedium: <default("UnitDiskRadioMedium")> like IRadioMedium {
            @display("p=580,275");
        }
        hostA: AdhocHost {
	    parameters:
                @display("p=50,325");
       }
        host2: TestHost {
          @display("p=50,325");
       }
	host3: TestHost {
          @display("p=50,400");
      }
      host4: TestHost {
          @display("p=150,325");
       }
        host5: TestHost {
          @display("p=150,400");
      }
	host6: TestHost {
          @display("p=250,325");
       }
        host7: TestHost {
          @display("p=250,400");
     }
	host8: TestHost {
          @display("p=350,325");
       }
        host9: TestHost {
          @display("p=350,400");
     }
	host10: TestHost {
          @display("p=450,325");
       }
        host11: TestHost {
          @display("p=450,400");
      }

               
}
