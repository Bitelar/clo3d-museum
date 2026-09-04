import SwiftUI
import RealityKit
import ARKit
import Vision
import Photos
import ReplayKit

struct ARScannerView: UIViewRepresentable {
    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        arView.automaticallyConfigureSession = false
        context.coordinator.configure(arView)
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {}

    final class Coordinator: NSObject, ARSessionDelegate, RPPreviewViewControllerDelegate {
        weak var arView: ARView?
        private var currentAnchor: AnchorEntity?
        private var pendingLookID: String?
        private var isShowingLook = false
        private var isScanningFrame = false
        private var lastVisionTime: TimeInterval = 0
        private let visionInterval: TimeInterval = 0.35
        private var recording = false
        private var statusLabel: UILabel?
        private var closeButton: UIButton?
        private var photoButton: UIButton?
        private var recordButton: UIButton?
        private var flashView: UIView?

        func configure(_ view: ARView) {
            arView = view
            view.session.delegate = self
            let configuration = ARWorldTrackingConfiguration()
            configuration.planeDetection = [.horizontal]
            configuration.environmentTexturing = .automatic
            if ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) {
                configuration.frameSemantics.insert(.sceneDepth)
            }
            view.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
            installOverlay(on: view)
        }

        private func installOverlay(on view: ARView) {
            let status = UILabel()
            status.translatesAutoresizingMaskIntoConstraints = false
            status.text = "ESCANEA EL CÓDIGO QR PARA VISUALIZAR EL DISEÑO"
            status.textColor = .white
            status.textAlignment = .center
            status.numberOfLines = 2
            status.font = .systemFont(ofSize: 13, weight: .semibold)
            status.backgroundColor = UIColor.black.withAlphaComponent(0.58)
            status.layer.cornerRadius = 18
            status.clipsToBounds = true
            view.addSubview(status)
            NSLayoutConstraint.activate([
                status.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 18),
                status.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                status.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, multiplier: 0.82),
                status.heightAnchor.constraint(greaterThanOrEqualToConstant: 48)
            ])
            statusLabel = status

            let close = circleButton(symbol: "xmark")
            close.isHidden = true
            close.addTarget(self, action: #selector(closeLook), for: .touchUpInside)
            view.addSubview(close)
            NSLayoutConstraint.activate([
                close.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -18),
                close.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 18),
                close.widthAnchor.constraint(equalToConstant: 50),
                close.heightAnchor.constraint(equalToConstant: 50)
            ])
            closeButton = close

            let controls = UIStackView()
            controls.translatesAutoresizingMaskIntoConstraints = false
            controls.axis = .horizontal
            controls.spacing = 14
            controls.distribution = .fillEqually
            controls.isHidden = true
            controls.tag = 9001
            view.addSubview(controls)
            NSLayoutConstraint.activate([
                controls.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                controls.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -22),
                controls.heightAnchor.constraint(equalToConstant: 58),
                controls.widthAnchor.constraint(equalToConstant: 132)
            ])

            let photo = circleButton(symbol: "camera.fill")
            photo.addTarget(self, action: #selector(takePhoto), for: .touchUpInside)
            controls.addArrangedSubview(photo)
            photoButton = photo

            let record = circleButton(symbol: "record.circle")
            record.addTarget(self, action: #selector(toggleRecording), for: .touchUpInside)
            controls.addArrangedSubview(record)
            recordButton = record

            let flash = UIView()
            flash.translatesAutoresizingMaskIntoConstraints = false
            flash.backgroundColor = .white
            flash.alpha = 0
            flash.isUserInteractionEnabled = false
            view.addSubview(flash)
            NSLayoutConstraint.activate([
                flash.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                flash.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                flash.topAnchor.constraint(equalTo: view.topAnchor),
                flash.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
            flashView = flash
        }

        private func circleButton(symbol: String) -> UIButton {
            let button = UIButton(type: .system)
            button.translatesAutoresizingMaskIntoConstraints = false
            button.setImage(UIImage(systemName: symbol), for: .normal)
            button.tintColor = .white
            button.backgroundColor = UIColor.black.withAlphaComponent(0.62)
            button.layer.cornerRadius = 25
            return button
        }

        private func setControlsVisible(_ visible: Bool) {
            closeButton?.isHidden = !visible
            (arView?.viewWithTag(9001) as? UIStackView)?.isHidden = !visible
        }

        func session(_ session: ARSession, didUpdate frame: ARFrame) {
            scanQRCodeIfNeeded(frame: frame)
            if pendingLookID != nil && currentAnchor == nil { tryPlacePendingLook(frame: frame) }
        }

        private func scanQRCodeIfNeeded(frame: ARFrame) {
            guard !isShowingLook, pendingLookID == nil, !isScanningFrame else { return }
            guard frame.timestamp - lastVisionTime >= visionInterval else { return }
            lastVisionTime = frame.timestamp
            isScanningFrame = true

            let request = VNDetectBarcodesRequest { [weak self] request, _ in
                guard let self else { return }
                defer { self.isScanningFrame = false }
                guard let observations = request.results as? [VNBarcodeObservation],
                      let payload = observations.compactMap({ $0.payloadStringValue }).first(where: { $0.uppercased().hasPrefix("LOOK_") }) else { return }
                let id = payload.uppercased().replacingOccurrences(of: "LOOK_", with: "")
                DispatchQueue.main.async {
                    guard !self.isShowingLook, self.pendingLookID == nil else { return }
                    self.pendingLookID = id
                    self.statusLabel?.text = "LOOK \(id) · DETECTANDO SUELO…"
                }
            }
            request.symbologies = [.QR]
            let handler = VNImageRequestHandler(cvPixelBuffer: frame.capturedImage, orientation: .right, options: [:])
            DispatchQueue.global(qos: .userInitiated).async {
                do { try handler.perform([request]) }
                catch { DispatchQueue.main.async { self.isScanningFrame = false } }
            }
        }

        private func tryPlacePendingLook(frame: ARFrame) {
            guard let id = pendingLookID, let view = arView else { return }
            let point = CGPoint(x: view.bounds.midX, y: view.bounds.height * 0.70)
            if let query = view.makeRaycastQuery(from: point, allowing: .existingPlaneGeometry, alignment: .horizontal),
               let hit = view.session.raycast(query).first {
                placeLook(id: id, at: hit.worldTransform)
                return
            }
            if let plane = frame.anchors.compactMap({ $0 as? ARPlaneAnchor }).first(where: { $0.alignment == .horizontal }) {
                placeLook(id: id, at: plane.transform)
            }
        }

        private func placeLook(id: String, at transform: simd_float4x4) {
            guard let view = arView else { return }
            let fileName = "look\(id.count >= 2 ? id : "0" + id)"
            guard let url = Bundle.main.url(forResource: fileName, withExtension: "usdz") else {
                pendingLookID = nil
                statusLabel?.text = "NO SE ENCONTRÓ \(fileName).usdz"
                return
            }
            do {
                let entity = try Entity.load(contentsOf: url)
                let anchor = AnchorEntity(world: transform)
                anchor.addChild(entity)
                view.scene.addAnchor(anchor)
                currentAnchor = anchor
                pendingLookID = nil
                isShowingLook = true
                statusLabel?.text = "LOOK \(id)"
                setControlsVisible(true)
            } catch {
                pendingLookID = nil
                statusLabel?.text = "NO SE PUDO CARGAR EL LOOK \(id)"
            }
        }

        @objc private func closeLook() {
            if recording { stopRecording(showPreview: false) }
            currentAnchor?.removeFromParent()
            currentAnchor = nil
            pendingLookID = nil
            isShowingLook = false
            setControlsVisible(false)
            statusLabel?.text = "ESCANEA EL CÓDIGO QR PARA VISUALIZAR EL DISEÑO"
        }

        @objc private func takePhoto() {
            guard let view = arView, isShowingLook else { return }
            flashView?.alpha = 0.8
            UIView.animate(withDuration: 0.22) { self.flashView?.alpha = 0 }
            view.snapshot(saveToHDR: false) { image in
                guard let image else { return }
                PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                    guard status == .authorized || status == .limited else { return }
                    PHPhotoLibrary.shared().performChanges { PHAssetChangeRequest.creationRequestForAsset(from: image) }
                }
            }
        }

        @objc private func toggleRecording() {
            guard isShowingLook else { return }
            recording ? stopRecording(showPreview: true) : startRecording()
        }

        private func startRecording() {
            let recorder = RPScreenRecorder.shared()
            guard recorder.isAvailable else { statusLabel?.text = "GRABACIÓN NO DISPONIBLE"; return }
            recorder.startRecording { [weak self] error in
                DispatchQueue.main.async {
                    guard let self else { return }
                    if error == nil {
                        self.recording = true
                        self.recordButton?.tintColor = .systemRed
                        self.statusLabel?.text = "GRABANDO LOOK"
                    } else { self.statusLabel?.text = "NO SE PUDO INICIAR LA GRABACIÓN" }
                }
            }
        }

        private func stopRecording(showPreview: Bool) {
            guard recording else { return }
            RPScreenRecorder.shared().stopRecording { [weak self] preview, error in
                DispatchQueue.main.async {
                    guard let self else { return }
                    self.recording = false
                    self.recordButton?.tintColor = .white
                    self.statusLabel?.text = self.isShowingLook ? "LOOK EN AR" : "ESCANEA EL CÓDIGO QR PARA VISUALIZAR EL DISEÑO"
                    guard showPreview, error == nil, let preview else { return }
                    preview.previewControllerDelegate = self
                    self.topViewController()?.present(preview, animated: true)
                }
            }
        }

        func previewControllerDidFinish(_ previewController: RPPreviewViewController) { previewController.dismiss(animated: true) }

        private func topViewController() -> UIViewController? {
            guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController else { return nil }
            var top = root
            while let presented = top.presentedViewController { top = presented }
            return top
        }
    }
}
