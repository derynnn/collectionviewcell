//
//  ViewController.swift
//  collectionviewcell
//
//  Created by Anastasia Tochilova  on 26.03.2024.
//

import UIKit
import AVFoundation

final class CellViewController: UIViewController {

    // MARK: - Properties

    private var photos: [UIImage?] = []
    
    // MARK: - Lazy Properties
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 10
        layout.itemSize = CGSize(width: (view.frame.size.width - 30) / 2, height: (view.frame.size.width - 30) / 2)

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .systemBackground
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "Cell")
        return collectionView
    }()

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        checkCameraAccess()
    }

    // MARK: - Setup

    private func setupCollectionView() {
        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    // MARK: - Camera Access
    
    func checkCameraAccess() {
        let cameraAccessGranted = UserDefaults.standard.bool(forKey: "CameraAccessGranted")
        if !cameraAccessGranted {
            AVCaptureDevice.requestAccess(for: .video) { granted in
                UserDefaults.standard.set(granted, forKey: "CameraAccessGranted")
                if granted {
                    DispatchQueue.main.async {
                        self.showCamera()
                    }
                } else {
                    DispatchQueue.main.async {
                        self.showCameraAccessDeniedAlert()
                    }
                }
            }
        }
    }
}

// MARK: - UICollectionViewDataSource

extension CellViewController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // Limit cell count to 50
        return 50
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)

        let contentView = cell.contentView
        contentView.subviews.forEach { $0.removeFromSuperview() }

        if indexPath.row == 0 {
            configurePlusButton(for: contentView)
        } else if let image = photos[indexPath.row] {
            configureImage(for: contentView, with: image)
        } else {
            cell.backgroundColor = .clear
        }

        return cell
    }

    private func configurePlusButton(for contentView: UIView) {
        let plusButton = UIButton(type: .system)
        plusButton.setImage(UIImage(systemName: "plus"), for: .normal)
        plusButton.tintColor = .systemBlue
        plusButton.frame = contentView.bounds
        plusButton.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        plusButton.addTarget(self, action: #selector(plusButtonTapped), for: .touchUpInside)
        contentView.addSubview(plusButton)
    }

    private func configureImage(for contentView: UIView, with image: UIImage) {
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.frame = contentView.bounds
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        contentView.addSubview(imageView)
    }

    @objc private func plusButtonTapped() {
        let cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
        switch cameraAuthorizationStatus {
        case .authorized:
            self.showCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                UserDefaults.standard.set(granted, forKey: "CameraAccessGranted")
                if granted {
                    DispatchQueue.main.async {
                        self.showCamera()
                    }
                } else {
                    DispatchQueue.main.async {
                        self.showCameraAccessDeniedAlert()
                    }
                }
            }
        case .denied, .restricted:
            showCameraAccessDeniedAlert()
        @unknown default:
            break
        }
    }
}

// MARK: - UICollectionViewDelegate

extension CellViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            plusButtonTapped()
        }
    }
}

// MARK: - UIImagePickerControllerDelegate, UINavigationControllerDelegate

extension CellViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        
        guard let image = info[.originalImage] as? UIImage else { return }
        
        var nearestEmptyIndex: Int?
        for index in 1..<photos.count {
            if photos[index] == nil {
                nearestEmptyIndex = index
                break
            }
        }
        if let nearestIndex = nearestEmptyIndex {
            if nearestIndex < photos.count {
                photos[nearestIndex] = image
                collectionView.reloadItems(at: [IndexPath(item: nearestIndex, section: 0)])
            } else {
                photos.append(image)
                collectionView.reloadData()
            }
        }
    }

    private func showCamera() {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = .camera
            present(imagePicker, animated: true, completion: nil)
        }
    }

    private func showCameraAccessDeniedAlert() {
        let alertController = UIAlertController(title: "Camera Access Denied", message: "Please grant access to use the camera. You can enable camera access in Settings.", preferredStyle: .alert)
        let settingsAction = UIAlertAction(title: "Settings", style: .default) { _ in
            guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
            if UIApplication.shared.canOpenURL(settingsURL) {
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
                } else {
                    UIApplication.shared.openURL(settingsURL)
                }
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)

        alertController.addAction(settingsAction)
        alertController.addAction(cancelAction)

        present(alertController, animated: true, completion: nil)
    }
}
