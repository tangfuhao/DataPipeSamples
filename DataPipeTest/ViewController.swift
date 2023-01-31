//
//  ViewController.swift
//  DataPipeTest
//
//  Created by fuhao on 2023/1/19.
//

import UIKit

class ViewController: UIViewController {
    var dataPipe: CSDataPipe?
    
    
    
    var displayLink: CADisplayLink?
    var progress: Int = 0
    
    
    var tempDataPipes = [CSDataPipe]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        displayLink = CADisplayLink(target: self, selector: #selector(handleDisplayLink))
        displayLink?.add(to: .main, forMode: .default)
        
        
        
        
        //Create data pipe
//        let dataPipe = CSDataPipe()
//        self.dataPipe = dataPipe
//
//        let dataSource = CameraSource()
//        let dataProcesser = YUV2RGBProcessor()
//        dataProcesser.connectInput(input: dataSource)
//        dataPipe.setMainInputAndOutput(input: dataSource, output: dataProcesser)
//
//        dataPipe.ReceiveData { pixelBuffer in
//            print("width: \(CVPixelBufferGetWidth(pixelBuffer))")
//        }
//        dataPipe.PullPixelData()

    }
    
    
    @objc func handleDisplayLink() {
        progress += 1
        
        
        if progress % 60 == 40 {
            progress = 0
            tempDataPipes.removeFirst()
        }else if progress % 60 == 10 {
            tempDataPipes.append(CSDataPipe())
        }
        

    }

}

