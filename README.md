# OSX-Sample-Converter

![](/mpc-convertV3_github.jpg)

This is an OS X utility app to help owners of the Akai MPC sampler series. The main issues when importing sound samples onto an MPC device are: the format of the files, and the file name length. If the files are in the wrong sound format they wont play, and if the names are too long you might not be able to differentiate on the small screen (as they will be truncated by the OS). As a user of the MPC, I was well aware of these issues; so its nice to have something new that helps.

From a tech perspective: I created the viewControllers in Swift, and the rest of the code is in Objective-C. It uses Apple’s ‘Core Audio’ framework to do all the sample rate / bit depth conversion.
