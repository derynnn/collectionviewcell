//
//  ViewController.swift
//  collectionviewcell
//
//  Created by Anastasia Tochilova  on 26.03.2024.
//

import UIKit
import AVFoundation

class CellViewController: UIViewController {
    
    // MARK: - Properties
    
    private var collectionView: UICollectionView!
    private var photos: [UIImage?] = Array(repeating: nil, count: 8)
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
    }
    
    // MARK: - Setup
    
    private func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 10
        layout.itemSize = CGSize(width: (view.frame.size.width - 30) / 2, height: (view.frame.size.width - 30) / 2)
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .systemBackground
        collectionView.contentInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10) // Add space from the device borders
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "Cell")
        view.addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

// MARK: - UICollectionViewDataSource, UICollectionViewDelegate

extension CellViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)
        cell.contentView.backgroundColor = indexPath.row == 0 ? .systemGray : getColorForIndex(index: indexPath.row)
        
        if indexPath.row == 0 {
            configurePlusButton(for: cell.contentView)
        } else if let image = photos[indexPath.row] {
            configureImage(for: cell.contentView, with: image)
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
    
    private func getColorForIndex(index: Int) -> UIColor {
        let colors: [UIColor] = [.systemBrown, .systemTeal, .systemBlue, .systemPurple, .systemIndigo, .systemPurple, .systemGreen, .systemGreen]
        return colors[(index - 1) % colors.count]
    }
    
    @objc private func plusButtonTapped() {
        let cameraAccessGranted = UserDefaults.standard.bool(forKey: "CameraAccessGranted")
        if cameraAccessGranted {
            self.showCamera()
        } else {
            let alertController = UIAlertController(title: "Camera Access", message: "This app requires access to your camera to take photos.", preferredStyle: .alert)
            
            let allowAction = UIAlertAction(title: "Allow", style: .default) { _ in
                self.checkCameraPermission()
            }
            let declineAction = UIAlertAction(title: "Decline", style: .cancel) { _ in
                self.showCameraAccessDeniedAlert()
            }
            
            alertController.addAction(allowAction)
            alertController.addAction(declineAction)
            
            present(alertController, animated: true, completion: nil)
        }
    }
}

// MARK: - UIImagePickerControllerDelegate, UINavigationControllerDelegate

extension CellViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.originalImage] as? UIImage {
            let nextIndex = getNextEmptyIndex()
            guard nextIndex < photos.count else {
                picker.dismiss(animated: true, completion: nil)
                return
            }
            photos[nextIndex] = image
            collectionView.reloadItems(at: [IndexPath(item: nextIndex, section: 0)])
        }
        picker.dismiss(animated: true, completion: nil)
    }
    
    private func getNextEmptyIndex() -> Int {
        for (index, photo) in photos.enumerated() {
            if photo == nil && index != 0 {
                return index
            }
        }
        return photos.count
    }
}

// MARK: - Camera Handling

extension CellViewController {
    
    private func checkCameraPermission() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            if granted {
                UserDefaults.standard.set(true, forKey: "CameraAccessGranted")
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
