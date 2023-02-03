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
        cameraCapture?.stopCapture()
        cameraCapture = nil
    }
    
    func onRegisterOutputDataType() -> CSDataType {
        return CSDataType(pixelParams: CSPixelParams(width: 640, height: 480, dataCategory: .NV21))
    }

}

extension CameraSource: CameraCapturePushDelegate {
    func myVideoCapture(_ capture: CameraCapture, didOutputSampleBuffer pixelBuffer: CVPixelBuffer, rotation: Int, timeStamp: CMTime) {
//        if CVPixelBufferIsPlanar(pixelBuffer) {
//            let planeCount = CVPixelBufferGetPlaneCount(pixelBuffer)
//            for index in 0...planeCount {
//                print("index:\(index), WidthOfPlane: \(CVPixelBufferGetWidthOfPlane(pixelBuffer, index)), bytesPerRowOfPlane: \(CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, index)) )")
//            }
//            
//            
//        }


        let swiftObjectRef = UnsafeRawPointer(Unmanaged.passUnretained(pixelBuffer).toOpaque())
        
        storePixelData(pixelBuffer: pixelBuffer)
    }
}
