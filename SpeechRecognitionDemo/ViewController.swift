//
//  ViewController.swift
//  SpeechRecognitionDemo
//
//  Created by Randy Fong on 5/23/19.
//  Copyright © 2019 Randall Fong Inc. All rights reserved.
//

import UIKit
import AVFoundation
import Speech

class ViewController: UIViewController {
    @IBOutlet weak var recognizedPhrase: UILabel!
    
    @IBOutlet weak var lastRecognizedPhraseLabel: UILabel!
    @IBAction func startSpeakingButtonPressed(_ sender: Any) {
        // Initialize SpeechRecognition
        let speechToText = SpeechRecognition()
        speechToText.audioEngine = AVAudioEngine()
        speechToText.speechRecognizer = SFSpeechRecognizer()
        speechToText.request = SFSpeechAudioBufferRecognitionRequest()
        
        // Start Speech Recognition and respond to words
        // or phrases transcribed, or respond to errors
        speechToText.recognizeSpeech()  { [unowned self] result in
            switch result {
            case .success(let phrase):
                self.lastRecognizedPhraseLabel.isHidden = false
                self.recognizedPhrase.text = phrase
            case .failure(let error):
                switch error {
                case .speechUnauthorized(let message):
                    self.showAlert(message, for: "Speech Authorization Error")
                case .unableToContinue(let message):
                    self.showAlert(message, for: "Speech to Text Error")
                case .warning(let message):
                    self.showAlert(message, for: "Speech to Text Warning")
                case .informational(let message):
                    self.showAlert(message, for: "Speech to Text")
                }
            }
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    private func showAlert(_ message: String, for title: String) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert)
        let okAction = UIAlertAction(
            title: "OK",
            style: .default,
            handler: nil)
        alert.addAction(okAction)
        present(alert, animated: true)
    }
    
}

