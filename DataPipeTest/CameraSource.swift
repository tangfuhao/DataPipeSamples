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
        
        setInputDataParams(params: ["1":"2","3":"4"])
        
        cameraCapture = CameraCapture(delegate: self)
        cameraCapture?.startCapture(ofCamera: .front)
    }
}

extension CameraSource: CameraCapturePushDelegate {
    func myVideoCapture(_ capture: CameraCapture, didOutputSampleBuffer pixelBuffer: CVPixelBuffer, rotation: Int, timeStamp: CMTime) {
        setPixelData(pixelBuffer: pixelBuffer)
    }
}
