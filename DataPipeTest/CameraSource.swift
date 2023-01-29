//
//  CameraSource.swift
//  DataPipeTest
//
//  Created by fuhao on 2023/1/26.
//

import Foundation
import CoreVideo
import CoreMedia


class CameraSource : CSDataSource {
    var cameraCapture: CameraCapture?
    
    override func onInit() {
        super.onInit()
        
        registerInputDataFormat(index: 0, type: .PixelBuffer)
        
        cameraCapture = CameraCapture(delegate: self)
        cameraCapture?.startCapture(ofCamera: .front)
    }
}

extension CameraSource: CameraCapturePushDelegate {
    func myVideoCapture(_ capture: CameraCapture, didOutputSampleBuffer pixelBuffer: CVPixelBuffer, rotation: Int, timeStamp: CMTime) {
        pushPixelData(pixelBuffer: pixelBuffer)
    }
}
