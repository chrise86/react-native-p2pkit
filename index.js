/**
 * @providesModule P2PKit
 * @flow
 */
'use strict';

import {
  NativeModules,
  NativeEventEmitter
 } from 'react-native';

const { PPKReactBridge } = NativeModules;

export default class P2PKit {

  static p2pkitCallbackHandler_;
  static p2pkitCallbackEmitter = new NativeEventEmitter(PPKReactBridge);

  static subscription = P2PKit.p2pkitCallbackEmitter.addListener(
    'callback',
    (nativeCallback) => {
      if(P2PKit.p2pkitCallbackHandler_[nativeCallback.methodName]) {
        P2PKit.p2pkitCallbackHandler_[nativeCallback.methodName](nativeCallback.parms);
      }
    }
  )

  static enable(appkey, p2pkitCallbackHandler){

      if(!p2pkitCallbackHandler){
        throw 'You must enable p2pkit with appropriate callbacks';
      }

      P2PKit.p2pkitCallbackHandler_ = p2pkitCallbackHandler;

      PPKReactBridge.enable(appkey);
    }

    static disable(){
      PPKReactBridge.disable();
    }

    static getMyPeerId(myPeerId){
      PPKReactBridge.getMyPeerId();
    }

    static startDiscovery(discoveryInfo){
      PPKReactBridge.startDiscovery(discoveryInfo);
    }

    static stopDiscovery(){
      PPKReactBridge.stopDiscovery();
    }

    static enableProximityRanging(){
      PPKReactBridge.enableProximityRanging();
    }

    static pushNewDiscoveryInfo(discoveryInfo){
      PPKReactBridge.pushNewDiscoveryInfo(discoveryInfo);
    }

};
