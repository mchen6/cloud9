﻿/*   SoundManager 2: Javascript Sound for the Web   ----------------------------------------------   http://schillmania.com/projects/soundmanager2/   Copyright (c) 2008, Scott Schiller. All rights reserved.   Code licensed under the BSD License:   http://www.schillmania.com/projects/soundmanager2/license.txt   V2.77a.20080901   Flash 9 / ActionScript 3 version*/package {import flash.display.Sprite;import flash.system.Security;import flash.events.*;import flash.media.Sound;import flash.media.SoundChannel;import flash.media.SoundMixer;import flash.utils.setInterval;import flash.utils.clearInterval;import flash.utils.Dictionary;import flash.utils.Timer;import flash.net.URLLoader;import flash.net.URLRequest;import flash.xml.*;import flash.external.ExternalInterface; // woopublic class SoundManager2_AS3 extends Sprite {  // Cross-domain security exception stuffs  // HTML on foo.com loading .swf hosted on bar.com? Define your "HTML domain" here to allow JS+Flash communication to work.  // See http://livedocs.adobe.com/flash/9.0/ActionScriptLangRefV3/flash/system/Security.html#allowDomain()  // Security.allowDomain("foo.com");  public var self:Object = this;  // internal objects  public var sounds:Array = []; // indexed string array  public var soundObjects:Dictionary = new Dictionary(); // associative Sound() object Dictionary type  public var timerInterval:uint = 50;  public var timer:Timer = null;  public var pollingEnabled:Boolean = false; // polling (timer) flag - disabled by default, enabled by JS->Flash call  public var debugEnabled:Boolean = true;    // Flash debug output enabled by default, disabled by JS call  public var soundMixer:SoundMixer = new SoundMixer();  public var loaded:Boolean = false;	public var playerID:String;	public var sID:String = "soundmgr2";  public function SoundManager2_AS3() {    //ExternalInterface.addCallback('_load', _load);    //ExternalInterface.addCallback('_unload', _unload);    //ExternalInterface.addCallback('_stop', _stop);    //ExternalInterface.addCallback('_start', _start);    //ExternalInterface.addCallback('_pause', _pause);    //ExternalInterface.addCallback('_setPosition', _setPosition);    //ExternalInterface.addCallback('_setPan', _setPan);    //ExternalInterface.addCallback('_setVolume', _setVolume);    //ExternalInterface.addCallback('_setPolling', _setPolling);    //ExternalInterface.addCallback('_externalInterfaceTest', _externalInterfaceTest);    //ExternalInterface.addCallback('_disableDebug', _disableDebug);    //ExternalInterface.addCallback('_loadFromXML', _loadFromXML);    //ExternalInterface.addCallback('_createSound', _createSound);    //ExternalInterface.addCallback('_destroySound', _destroySound);		playerID = loaderInfo.parameters.playerID;    if (ExternalInterface.available) {      ExternalInterface.addCallback('callMethod', callMethod);      sendEvent("init", {state: 1});		}  } // SoundManager2()  // methods  // -----------------------------------    private function sendEvent(event:String, object:Object):Object {    return ExternalInterface.call('jpf.flash.callMethod', this.playerID || 1, 'event', event, object);  }  public function callJS(method:String, data:Object):Object {    return ExternalInterface.call('jpf.flash.callMethod', this.playerID || 1, method, data);  }  public function callMethod():void {    var method:String = String(arguments.shift());    this[method].apply(this, arguments);  }  public function checkLoadProgress(e:Event):void {    var oSound:Object = e.target;    var bL:int = oSound.bytesLoaded;    var bT:int = oSound.bytesTotal;    var nD:int = oSound.length||0;    sendEvent("progress",{bytesLoaded:bL,totalBytes:bT,totalTime:nD});    if (bL && bT && bL != oSound.lastValues.bytes) {      oSound.lastValues.bytes = bL;      sendEvent("progress",{bytesLoaded:bL,totalBytes:bT,totalTime:nD});    }  }  public function checkProgress():void {    var bL:int = 0;    var bT:int = 0;    var nD:int = 0;    var nP:int = 0;    var lP:Number = 0;    var rP:Number = 0;    var oSound:SoundManager2_SMSound_AS3 = null;    var oSoundChannel:flash.media.SoundChannel = null;    var sMethod:String = null;    var newPeakData:Boolean = false;    var newWaveformData:Boolean = false;    var newEQData:Boolean = false;    for (var i:int = 0, j:int = sounds.length; i < j; i++) {      oSound = soundObjects[sounds[i]];      if (!oSound) continue; // if sounds are destructed within event handlers while this loop is running, may be null      oSoundChannel = soundObjects[sounds[i]].soundChannel;      bL = oSound.bytesLoaded;      bT = oSound.bytesTotal;      nD = int(oSound.length||0); // can sometimes be null with short MP3s? Wack.      if (oSoundChannel) {        nP = (oSoundChannel.position||0);        if (oSound.usePeakData) {          lP = int((oSoundChannel.leftPeak)*1000)/1000;          rP = int((oSoundChannel.rightPeak)*1000)/1000;        } else {          lP = 0;          rP = 0;        }      } else {        // stopped, not loaded or feature not used        nP = 0;      }      // loading progress      if (bL && bT && bL != oSound.lastValues.bytes) {        oSound.lastValues.bytes = bL;        sendEvent("progress", {bytesLoaded: bL, totalBytes: bT, totalTime: nD});      }      // peak data      if (oSoundChannel && oSound.usePeakData) {        if (lP != oSound.lastValues.leftPeak) {          oSound.lastValues.leftPeak = lP;          newPeakData = true;        }        if (rP != oSound.lastValues.rightPeak) {          oSound.lastValues.rightPeak = rP;          newPeakData = true;        }      }      // raw waveform + EQ spectrum data      if (oSoundChannel) {        if (oSound.useWaveformData) {          try {            oSound.getWaveformData();          } catch(e:Error) {            oSound.useWaveformData = false;          }        }        if (oSound.useEQData) {          try {            oSound.getEQData();          } catch(e:Error) {            oSound.useEQData = false;          }        }        if (oSound.waveformDataArray != oSound.lastValues.waveformDataArray) {          oSound.lastValues.waveformDataArray = oSound.waveformDataArray;          newWaveformData = true;        }        if (oSound.eqDataArray != oSound.lastValues.eqDataArray) {          oSound.lastValues.eqDataArray = oSound.eqDataArray;          newEQData = true;        }      }      if (typeof nP != 'undefined' && nP != oSound.lastValues.position) {        oSound.lastValues.position = nP;        sendEvent("playheadUpdate",{          playheadTime: nP,          totalTime   : nD,          peakData    : (newPeakData ? {leftPeak: lP, rightPeak: rP} : null),          waveData    : (newWaveformData ? oSound.waveformDataArray : null),          eqData      : (newEQData ? oSound.eqDataArray : null)});        // if position changed, check for near-end        if (oSound.didJustBeforeFinish != true && oSound.loaded == true && oSound.justBeforeFinishOffset > 0 && nD-nP <= oSound.justBeforeFinishOffset) {          // fully-loaded, near end and haven't done this yet..          sendEvent("justbeforecomplete",{timeLeft: (nD-nP)});          oSound.didJustBeforeFinish = true;        }      }    }  }  public var counter:int = 0;  public function onLoad(e:Event):void {    checkProgress(); // ensure progress stats are up-to-date    var oSound:Object = e.target;    oSound.loaded = true;		sendEvent("ready",{state: 1});    // force duration update (doesn't seem to be always accurate)    sendEvent("progress",{bytesLoaded: oSound.bytesLoaded,totalBytes: oSound.bytesTotal,totalTime: oSound.length});    // TODO: Determine if loaded or failed - bSuccess?    // ExternalInterface.call(baseJSObject+"['"+oSound.sID+"']._onload",bSuccess?1:0);  }  public function onID3(e:Event):void {    // --- NOTE: BUGGY? ---    // --------------------    // TODO: Investigate holes in ID3 parsing - for some reason, Album will be populated with Date if empty and date is provided. (?)    // ID3V1 seem to parse OK, but "holes" / blanks in ID3V2 data seem to get messed up (eg. missing album gets filled with date.)    // iTunes issues: onID3 was not called with a test MP3 encoded with iTunes 7.01, and what appeared to be valid ID3V2 data.    // May be related to thumbnails for album art included in MP3 file by iTunes. See http://mabblog.com/blog/?p=33    var oSound:Object = e.target;    var id3Data:Array = [];    var id3Props:Array = [];    for (var prop:String in oSound.id3) {      id3Props.push(prop);      id3Data.push(oSound.id3[prop]);      // writeDebug('id3['+prop+']: '+oSound.id3[prop]);    }    sendEvent("id3",{properties: id3Props, data: id3Data});    // unhook own event handler, prevent second call (can fire twice as data is received - ID3V2 at beginning, ID3V1 at end.)    // Therefore if ID3V2 data is received, ID3V1 is ignored.    // soundObjects[oSound.sID].onID3 = null;    oSound.removeEventListener(Event.ID3,onID3);  }  public function registerOnComplete():void {    soundObjects[sID].soundChannel.addEventListener(Event.SOUND_COMPLETE, function():void {      this.didJustBeforeFinish = false; // reset      checkProgress();      sendEvent("complete", {state: 1});      // reset position?    });  }  public function setPosition(nSecOffset:Number,isPaused:Boolean):void {    var s:SoundManager2_SMSound_AS3 = soundObjects[sID];    // stop current channel, start new one.    s.lastValues.position = nSecOffset; // s.soundChannel.position;    if (s.soundChannel) {      s.soundChannel.stop();      // writeDebug('setPosition: '+nSecOffset+', '+(s.lastValues.nLoops?s.lastValues.nLoops:1));      s.start(nSecOffset,s.lastValues.nLoops||1); // start playing at new position      checkProgress(); // force UI update      registerOnComplete();      if (isPaused) {        // writeDebug('last position: '+s.lastValues.position+' vs '+s.soundChannel.position);        s.soundChannel.stop();      }    }  }  public function loadSound(sURL:String, bStream:Boolean = true, bAutoPlay:Boolean = false):void {    if (typeof bAutoPlay == 'undefined') bAutoPlay = false;    var s:SoundManager2_SMSound_AS3 = soundObjects[sID];    var didRecreate:Boolean = false;    if (s.didLoad == true) {      // need to recreate sound      didRecreate = true;      var ns:Object = new Object();      ns.sID = s.sID;      ns.justBeforeFinishOffset = s.justBeforeFinishOffset;      ns.usePeakData = s.usePeakData;      ns.useWaveformData = s.useWaveformData;      ns.useEQData = s.useEQData;      destroySound();      createSound(sURL,ns.justBeforeFinishOffset,ns.usePeakData,ns.useWaveformData,ns.useEQData);      s = soundObjects[sID];    }    checkProgress();    if (!s.didLoad) {      s.addEventListener(Event.ID3, onID3);      s.addEventListener(Event.COMPLETE, onLoad);    }    // s.addEventListener(ProgressEvent.PROGRESS, checkLoadProgress); // May be called often, potential CPU drain    // s.addEventListener(Event.FINISH, onFinish);    s.loaded = true;    s.didLoad = true;    // if (didRecreate || s.sURL != sURL) {    // don't try to load if same request already made    s.sURL = sURL;    try {      s.loadSound(sURL,bStream);    } catch(e:Error) {      // oh well    }    //    }    s.didJustBeforeFinish = false;    if (bAutoPlay != true) {      //s.soundChannel.stop(); // prevent default auto-play behaviour      //sendEvent('debug', 'auto-play stopped');    } else {      //sendEvent('debug', 'auto-play allowed');      //s.start(0,1);      //registerOnComplete();    }  }  public function unloadSound(sURL:String):void {    var s:SoundManager2_SMSound_AS3 = soundObjects[sID];    removeEventListener(Event.ID3,onID3);    removeEventListener(Event.COMPLETE, onLoad);    s.paused = false;    s.soundChannel.stop();    try {      if (s.didLoad != true) s.close(); // close stream only if still loading?    } catch(e:Error) {      // stream may already have closed if sound loaded, etc.      // oh well    }    // destroy and recreate Flash sound object, try to reclaim memory    var ns:Object = new Object();    ns.sID = s.sID;    ns.justBeforeFinishOffset = s.justBeforeFinishOffset;    ns.usePeakData = s.usePeakData;    ns.useWaveformData = s.useWaveformData;    ns.useEQData = s.useEQData;    destroySound();    createSound(sURL,ns.justBeforeFinishOffset,ns.usePeakData,ns.useWaveformData,ns.useEQData);  }  public function createSound(sURL:String, justBeforeFinishOffset:int = 0, usePeakData:Boolean = false, useWaveformData:Boolean = false, useEQData:Boolean = false):void {    soundObjects[sID] = new SoundManager2_SMSound_AS3(sID,sURL,usePeakData,useWaveformData,useEQData);    var s:SoundManager2_SMSound_AS3 = soundObjects[sID];    // s.setVolume(100);    s.didJustBeforeFinish = false;    s.sID = sID;    s.sURL = sURL;    s.paused = false;    s.loaded = false;    s.justBeforeFinishOffset = justBeforeFinishOffset||0;    s.lastValues = {      bytes: 0,      position: 0,      nLoops: 1,      leftPeak: 0,      rightPeak: 0    };    if (!(sID in sounds)) sounds.push(sID);    // sounds.push(sID);  }  public function destroySound():void {    // for the power of garbage collection! .. er, Greyskull!    var s:SoundManager2_SMSound_AS3 = (soundObjects[sID]||null);    if (s) {      for (var i:int=0, j:int=sounds.length; i<j; i++) {        if (sounds[i] == s) {          sounds.splice(i,1);          continue;        }      }      s = null;      soundObjects[sID] = null;      delete soundObjects[sID];    }  }  public function stopSound(bStopAll:Boolean):void {    // stop this particular instance (or "all", based on parameter)    if (bStopAll) {      sendEvent('alert','Flash: need _stop for all sounds');      // SoundManager2_AS3.display.stage.stop(); // _root.stop();      // this.soundChannel.stop();      // soundMixer.stop();    } else {	    var s:SoundManager2_SMSound_AS3 = soundObjects[sID];      s.soundChannel.stop();      s.paused = false;      s.didJustBeforeFinish = false;    }  }  public function startSound(nLoops:int, nMsecOffset:int):void {    var s:SoundManager2_SMSound_AS3 = soundObjects[sID];    s.lastValues.paused = false; // reset pause if applicable    s.lastValues.nLoops = (nLoops||1);    s.lastValues.position = nMsecOffset;    s.start(nMsecOffset,nLoops);    registerOnComplete();  }  public function pauseSound():void {    var s:SoundManager2_SMSound_AS3 = soundObjects[sID];    if (!s.paused) {      // reference current position, stop sound      s.paused = true;       s.lastValues.position = s.soundChannel.position;      s.soundChannel.stop();    } else {      // resume playing from last position      s.paused = false;      s.start(s.lastValues.position,s.lastValues.nLoops);      registerOnComplete();    }  }  public function setPan(nPan:Number):void {    soundObjects[sID].setPan(nPan);  }   public function setVolume(nVol:Number):void {    soundObjects[sID].setVolume(nVol);  }  public function setPolling(bPolling:Boolean):void {    pollingEnabled = bPolling;    if (timer == null && pollingEnabled) {      // timer = flash.utils.setInterval(checkProgress,timerInterval);      timer = new Timer(timerInterval,0);      // timer.addEventListener(TimerEvent.TIMER, checkProgress);      timer.addEventListener(TimerEvent.TIMER, function():void{checkProgress();}); // direct reference eg. checkProgress doesn't work? .. odd.      timer.start();    } else if (timer && !pollingEnabled) {      // flash.utils.clearInterval(timer);      timer.reset();    }  }  // -----------------------------------  // end methods}// package}