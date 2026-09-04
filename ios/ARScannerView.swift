import SwiftUI
import RealityKit
import ARKit
import AVFoundation

struct ARScannerView: UIViewRepresentable {
    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        context.coordinator.arView = arView

        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        configuration.environmentTexturing = .automatic
        arView.session.run(configuration)

        context.coordinator.installOverlay(on: arView)
        context.coordinator.startQRDetection()
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {}

    final class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        weak var arView: ARView?
        private let captureSession = AVCaptureSession()
        private var currentAnchor: AnchorEntity?
        private var isShowingLook = false
        private var statusLabel: UILabel?
        private var closeButton: UIButton?

        func installOverlay(on view: ARView) {
            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.text = "ESCANEA EL CÓDIGO QR PARA VISUALIZAR EL DISEÑO"
            label.textColor = .white
            label.backgroundColor = UIColor.black.withAlphaComponent(0.55)
            label.textAlignment = .center
            label.numberOfLines = 0
            label.font = .systemFont(ofSize: 13, weight: .semibold)
            label.layer.cornerRadius = 18
            label.clipsToBounds = true
            view.addSubview(label)
            NSLayoutConstraint.activate([
                label.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 18),
                label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                label.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, multiplier: 0.86),
                label.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
            ])
            statusLabel = label

            let close = UIButton(type: .system)
            close.translatesAutoresizingMaskIntoConstraints = false
            close.setTitle("×", for: .normal)
            close.titleLabel?.font = .systemFont(ofSize: 34, weight: .light)
            close.tintColor = .white
            close.backgroundColor = UIColor.black.withAlphaComponent(0.55)
            close.layer.cornerRadius = 24
            close.isHidden = true
            close.addTarget(self, action: #selector(closeLook), for: .touchUpInside)
            view.addSubview(close)
            NSLayoutConstraint.activate([
                close.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -18),
                close.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 18),
                close.widthAnchor.constraint(equalToConstant: 48),
                close.heightAnchor.constraint(equalToConstant: 48)
            ])
            closeButton = close
        }

        func startQRDetection() {
            guard let device = AVCaptureDevice.default(for: .video),
                  let input = try? AVCaptureDeviceInput(device: device),
                  captureSession.canAddInput(input) else { return }
            captureSession.addInput(input)
            let output = AVCaptureMetadataOutput()
            guard captureSession.canAddOutput(output) else { return }
            captureSession.addOutput(output)
            output.setMetadataObjectsDelegate(self, queue: .main)
            output.metadataObjectTypes = [.qr]
            DispatchQueue.global(qos: .userInitiated).async { self.captureSession.startRunning() }
        }

        func metadataOutput(_ output: AVCaptureMetadataOutput,
                            didOutput metadataObjects: [AVMetadataObject],
                            from connection: AVCaptureConnection) {
            guard !isShowingLook,
                  let qr = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
                  let value = qr.stringValue,
                  value.hasPrefix("LOOK_") else { return }
            isShowingLook = true
            statusLabel?.text = "DETECTANDO SUELO…"
            loadLook(id: value.replacingOccurrences(of: "LOOK_", with: ""))
        }

        private func loadLook(id: String) {
            guard let view = arView else { return }
            let fileName = "look\(id.pad2)"
            guard let url = Bundle.main.url(forResource: fileName, withExtension: "usdz") else {
                statusLabel?.text = "MODELO \(id) NO ENCONTRADO"
                isShowingLook = false
                return
            }
            do {
                let model = try Entity.load(contentsOf: url)
                let anchor = AnchorEntity(plane: .horizontal, classification: .floor, minimumBounds: SIMD2<Float>(0.4, 0.4))
                anchor.addChild(model)
                view.scene.addAnchor(anchor)
                currentAnchor = anchor
                statusLabel?.text = "LOOK \(id)"
                closeButton?.isHidden = false
            } catch {
                statusLabel?.text = "NO SE PUDO CARGAR EL LOOK \(id)"
                isShowingLook = false
            }
        }

        @objc private func closeLook() {
            currentAnchor?.removeFromParent()
            currentAnchor = nil
            isShowingLook = false
            closeButton?.isHidden = true
            statusLabel?.text = "ESCANEA EL CÓDIGO QR PARA VISUALIZAR EL DISEÑO"
        }
    }
}

private extension String {
    var pad2: String { count >= 2 ? self : "0" + self }
}
