//
//  CameraSource.swift
//  DataPipeTest
//
//  Created by fuhao on 2023/1/26.
//

import Foundation
import CoreVideo
import CoreMedia


class CameraSource : CSSourcePProtocol {
    var cameraCapture: CameraCapture?
    func onInit() {
        cameraCapture = CameraCapture(delegate: self)
        cameraCapture?.startCapture(ofCamera: .front)
    }
    
    func onRelease() {
        
    }
    
    func onRegisterDataType() -> CSDataType {
        return CSDataType(format: .PixelBuffer)
    }

}

extension CameraSource: CameraCapturePushDelegate {
    func myVideoCapture(_ capture: CameraCapture, didOutputSampleBuffer pixelBuffer: CVPixelBuffer, rotation: Int, timeStamp: CMTime) {
        storePixelData(pixelBuffer: pixelBuffer)
    }
}
