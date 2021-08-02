Question in stack overflow: https://stackoverflow.com/posts/68621251

__________
This question is a broader description of the bug documented [here][1]. I'm reproducing the steps below on iPhone 8 and iOS 14.7.

How can I achieve my `AVAudioSession` and `AVAudioEngine` instances to work properly, even when I disconnect a microphone after setting it as a preferred input, since Route Change Notifications do not work in the situation above? 
___
When there are multiple audio inputs available to the iOS, I can set the active one with `.setPreferredInput(...)`.

When [`.setPreferredInput(...)`][2] is called, both the [`preferredInput`][3] and the active input given by [`currentRoute`][4] are set to the requested input/microphone.

Also, I can subscribe to [route change][5], [audio interruption][6] and OS Media [Reset][7]/[Lost][8] notifications given by the OS - this communication is managed by [`AVAudioSession`][9] - . These notifications work properly when I connect and disconnect IO audio devices, like wired earphones, wired EarPods, bluetooth headsets and so on. These notifications also work properly while I have a running [`AVAudioEngine`][10] in my application, with [input][11] and [output][12] nodes capturing and reproducing audio while these notifications are fired.

All the considerations here are being reproduced with `AVAudioEngine` [category][16] set to `[.playAndRecord][15]` and with the `AVAudioEngine` running as: `inputNode->mainMixerNode->outputNode`.


However, *a particular situation arrives when I select a microphone to be active, and then I disconnect this mic.* This is reproduced by calling `.setPreferredInput(...)` and unplugging the mic.

In the situation mentioned above, **the route change notification is not called**. Instead, **the OS Media Reset/Lost events MAY be called** in a range from some milliseconds, to 6 seconds, or even not being fired at all. While in this "empty" route state, the active input is preempted by the OS to be nil.

The uncertainty of the mentioned situation is a problem, because I cannot find a suited and secure solution for these steps above when they are reproduced. The user may, for example, ask for an audio node to play or to capture audio with an input node while the OS doesn't know how to handle the disconnected microphone. I attempted some workarounds, by double-checking if the active input is not nil in every critical action, but attempting to overwrite routes in the "idle" state between unplugging and OS Media Lost/Reset being fired did not work.


Also, notice that, EarPods are plugged while both the `AVAudioEngine` is running and the `AVAudioSession` instance is active, the EarPods are automatically set as the active input/output **WITHOUT** calling `.setPreferredInput(...)`, since it's the default OS behavior, which can be tracked by Route Change notifications. When the EarPods are unplugged in the following this situation, the OS gracefully handles it by firing [`.oldDeviceUnavailable`][13], and both the `AVAudioSession` and `AVAudioEngine` instances automatically follows to work with the built-in mic/speaker.  It doesn't happen when `.setPreferredInput(...)` is called before unplugging the EarPods.

My sample application is [here][14].

  [1]: https://stackoverflow.com/questions/65045877/avaudiosession-services-reset-when-capturing-input-from-bluetooth-device-that-di
  [2]: https://developer.apple.com/documentation/avfaudio/avaudiosession/1616491-setpreferredinput
  [3]: https://developer.apple.com/documentation/avfaudio/avaudiosession/1616536-preferredinput
  [4]:https://developer.apple.com/documentation/avfaudio/avaudiosession/1616453-currentroute
  [5]: https://developer.apple.com/documentation/avfaudio/avaudiosession/1616493-routechangenotification
  [6]: https://developer.apple.com/documentation/avfaudio/avaudiosession/1616596-interruptionnotification
  [7]: https://developer.apple.com/documentation/avfaudio/avaudiosession/1616540-mediaserviceswereresetnotificati
  [8]: https://developer.apple.com/documentation/avfaudio/avaudiosession/1616457-mediaserviceswerelostnotificatio
  [9]: https://developer.apple.com/documentation/avfaudio/avaudiosession
  [10]: https://developer.apple.com/documentation/avfaudio/avaudioengine
  [11]: https://developer.apple.com/documentation/avfaudio/avaudioengine/1386063-inputnode
  [12]: https://developer.apple.com/documentation/avfaudio/avaudioengine/1389103-outputnode
  [13]: https://developer.apple.com/documentation/avfaudio/avaudiosession/routechangereason/olddeviceunavailable
  [14]: https://github.com/miguelfs/audioroute_poc
  [15]: https://developer.apple.com/documentation/avfaudio/avaudiosession/category/1616568-playandrecord
  [16]: https://developer.apple.com/documentation/avfaudio/avaudiosession/category
