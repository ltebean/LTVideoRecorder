This project demonstrates how use CoreImage to add filter, drawing, and text to a video

The flow is: 
- for every frame, get CVPixelBuffer from a AVCaptureSession, convert it to a CIImage instance
- add filter to the CIImage
- add drawing and text layer to the CIImage
- render the CIImage to the screen
- write the CIImage to the file


<img src="https://raw.githubusercontent.com/ltebean/LTVideoRecorder/master/pics/1.jpg" width="180">  <img src="https://raw.githubusercontent.com/ltebean/LTVideoRecorder/master/pics/2.jpg" width="180">  <img src="https://raw.githubusercontent.com/ltebean/LTVideoRecorder/master/pics/3.jpg" width="180">

