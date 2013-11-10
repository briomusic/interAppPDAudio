interAppPDAudio
===============
#### This Project demos the CSAudioController, which can be used to make libPd Apps compatible with Apple's inter-app audio system.  
It is assumed that you are familiar with libPD and how to set up a libPD App in xCode.  
If you are not, please refer to the book __'Making musical Apps'__ by Peter Brinkmann. 
  
I also strongly recommend watching the video 602 __'What's new in CoreAudio'__ from the __WWDC2013__.  
Please also download and try out the _InterAppAudioSuite_, which is available as Apple sample code.  
The InterAppAudioHost from this Suite is necessary to try all aspects of inter-App audio functionality!  

####Project setup:
* clone this repository  
* in Terminal, navigate to 'submodules' folder  
* run 'git submodule init' and 'git submodule update'
* open the project in xcode and open the file 'PDAudioController.m'
* CUT the line '@property (nonatomic, retain) PdAudioUnit *audioUnit;	// out private PdAudioUni'  
* PASTE this line into 'PDAudioController.h' somewhere near the other properties.  
* this makes the audioUnit property public and visible to our subclass  
* (I know this is an ugly way of doing it, recommendations welcome)  
* The Project should build and run now.  

####Using this App:  
* on running this App you should see a piano keyboard which emits sine tones when played.  
* you should also see a transport panel. tapping the transport controls will result in a host error, because no host is connected at this stage.  

####Connecting a Host:
* I recommend using the InterAppAudioHost mentioned above. (Garageband and Looptical can also act as InterAppAudio hosts, but don't provide MIDI output.)  
* Launch your chosen InterAppAudio host and select interAppPDAudio from the list of nodes. (In order to receive MIDI from the host you need to select the instrument version, __not__ the generator version of the same name.)  
* Once your host has accepted and linked your node App, shuttle to the node App by tapping its icon.  
* Verify that you can still play and hear the sine piano. (It is now routed through the host App.)  
* You should also see the host App's icon on the transport panel. You can tap this to shuttle back to the host.  
* If you tap on the red record button in the transport panel, the host App starts recording. (The counter won't move, but the red button is pulsating to indicate that recording is in progress)  
* Play a few notes while in record. Then tap record again to stop the recording.  
* Tap rewind followed by play on the transport. After a few seconds you should be able to hear your recording.  
* If you are using the InterAppAudioHost mentioned above, you can also switch back to the host app and use the midi keyboard to play the sine piano.  

####Known Issues:
* The transport counter doesn't move. Some bug in one of the C methods, will figure it out later.  
* If the interAppPDAudio was not running while being launched by the host, there is no audio. will figure this one out later too.  

#####Feel free to check out my own libPD interApp audio project CloudSynth!  
* 
