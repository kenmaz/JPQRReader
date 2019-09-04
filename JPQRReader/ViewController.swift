//
//  ViewController.swift
//  JPQRReader
//
//  Created by kenmaz on 2019/09/04.
//  Copyright © 2019 net.kenmaz. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {

    private let session = AVCaptureSession()
    private let output = AVCaptureMetadataOutput()
    private var input: AVCaptureDeviceInput?

    lazy var previewLayer: CALayer = {
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        return layer
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        do {
            try setupVideo()
            previewLayer.frame = view.bounds
            view.layer.insertSublayer(previewLayer, at: 0)
        } catch {
            print(error)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !session.isRunning else { return }
        session.startRunning()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        guard session.isRunning else { return }
        session.stopRunning()
    }

    enum VideoError: Error {
        case denied
        case other
    }

    private func setupVideo() throws {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            break
        case .denied, .restricted:
            throw VideoError.denied
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { (auth) in
                if !auth {
                    print("not auth")
                }
            }
        @unknown default:
            throw VideoError.other
        }
        guard let device = AVCaptureDevice.default(for: .video) else {
            throw VideoError.other
        }
        guard let videoInput = try? AVCaptureDeviceInput(device: device) else {
            throw VideoError.other
        }
        self.input = videoInput

        output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)

        guard session.canAddOutput(output) else {
            throw VideoError.other
        }
        guard session.canAddInput(videoInput) else {
            throw VideoError.other
        }
        session.beginConfiguration()
        session.addInput(videoInput)
        session.addOutput(output)
        output.metadataObjectTypes = [.qr]
        session.commitConfiguration()
    }
}

extension ViewController: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        print(metadataObjects)
    }
}
